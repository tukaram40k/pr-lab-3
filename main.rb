require 'sinatra'
require 'sinatra/cross_origin'
require_relative 'lib/board/board'
require_relative 'lib/commands'
require_relative 'lib/controllers/server_logger'
require_relative 'lib/controllers/request_queue'

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
queue = RequestQueue.new
board.queue = queue

logger = ServerLogger.new(File.expand_path('logs/', File.dirname(__FILE__)))
logger.log_board(board.to_s)

set :port, port
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

  result = queue.enqueue do
    look(board, player_id)
  end

  if result.is_a?(Exception)
    status 409
    content_type 'text/plain'
    body "cannot look at the board: #{result.message}"
  else
    content_type 'text/plain'
    status 200
    body result
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

  result = queue.enqueue do
    flip(board, player_id, row, column)
  end

  if result.is_a?(Exception)
    status 409
    content_type 'text/plain'
    body "cannot flip this card: #{result.message}"
  else
    content_type 'text/plain'
    status 200
    body result
  end
end

get '/' do
  send_file 'public/index.html'
end

# GET /replace/:player_id/:from_card/:to_card
# Replaces all from_card with to_card on board.
get '/replace/:player_id/:from_card/:to_card' do
  player_id = params[:player_id]
  from_card = params[:from_card]
  to_card = params[:to_card]
  halt 400, 'missing params' unless [player_id, from_card, to_card].all? { |v| v && !v.empty? }

  logger.log_map(player_id, from_card, to_card)
  result = map(board, player_id, from_card, to_card)

  if result.is_a?(Exception)
    status 409
    content_type 'text/plain'
    body "cannot map cards: #{result.message}"
  else
    content_type 'text/plain'
    status 200
    body result
  end
end

# GET /watch/:player_id
# Waits until board changes, then returns new board state.
get '/watch/:player_id' do
  player_id = params[:player_id]
  halt 400, 'missing player_id' unless player_id && !player_id.empty?

  logger.log_watch(player_id)
  result = queue.watch do
    watch(board, player_id)
  end

  if result.is_a?(Exception)
    status 409
    content_type 'text/plain'
    body "watch failed: #{result.message}"
  else
    content_type 'text/plain'
    status 200
    body result
  end
end

set :public_folder, File.join(File.dirname(__FILE__), 'public')

after do
  puts "server now listening at http://localhost:#{port}" if request.path_info == '/'
end
