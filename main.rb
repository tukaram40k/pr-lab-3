require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require_relative 'lib/board'
require_relative 'lib/commands'
require_relative 'lib/server_logger'

# Command-line usage:
#   bundler exec ruby main.rb PORT FILENAME
#
# If PORT = 0, a random available port will be chosen.

if ARGV.length < 2
  abort "Usage: bundler exec ruby main.rb PORT FILENAME"
end

port = ARGV[0].to_i
filename = ARGV[1]
abort 'Invalid port' if port < 0
abort 'Missing board file' unless File.exist?(filename)

board = Board.parse_from_file(filename)

logger = ServerLogger.new(File.expand_path('logs/', File.dirname(__FILE__)))
logger.log_board(board.to_s)

set :port, port
set :environment, :production
set :bind, '0.0.0.0'

configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

# GET /look/:player_id
# Returns the board state from player’s perspective.
get '/look/:player_id' do
  player_id = params[:player_id]
  halt 400, 'missing player_id' unless player_id && !player_id.empty?

  logger.log_look(player_id)

  begin
    board_state = look(board, player_id)
    content_type 'text/plain'
    status 200
    body board_state
  rescue => e
    status 409
    content_type 'text/plain'
    body "cannot look at the board: #{e.message}"
  end
end

# GET /flip/:player_id/:row,:column
# Flips a card at row,column for player.
get '/flip/:player_id/:location' do
  player_id = params[:player_id]
  location = params[:location]
  halt 400, 'missing player_id or location' unless player_id && location

  row, column = location.split(',').map(&:to_i)
  logger.log_flip(player_id, row, column)

  begin
    board_state = flip(board, player_id, row, column)
    content_type 'text/plain'
    status 200
    body board_state
  rescue => e
    status 409
    content_type 'text/plain'
    body "cannot flip this card: #{e.message}"
  end
end

# GET /replace/:player_id/:from_card/:to_card
# Replaces all from_card with to_card on board.
get '/replace/:player_id/:from_card/:to_card' do
  player_id = params[:player_id]
  from_card = params[:from_card]
  to_card = params[:to_card]
  halt 400, 'missing params' unless [player_id, from_card, to_card].all? { |v| v && !v.empty? }

  board_state = map(board, player_id) do |card|
    card == from_card ? to_card : card
  end

  content_type 'text/plain'
  status 200
  body board_state
end

# GET /watch/:player_id
# Waits until board changes, then returns new board state.
get '/watch/:player_id' do
  player_id = params[:player_id]
  halt 400, 'missing player_id' unless player_id && !player_id.empty?

  board_state = watch(board, player_id)
  content_type 'text/plain'
  status 200
  body board_state
end

# Serve static HTML UI from /public
set :public_folder, File.join(File.dirname(__FILE__), 'public')

# Start message
after do
  puts "server now listening at http://localhost:#{port}" if request.path_info == '/'
end
