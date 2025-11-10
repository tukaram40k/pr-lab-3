class Board
  #
  # game board class
  # - @rows x @columns are the board dimensions
  # - @cards are the board's cards
  # - each card has value [String] - card's value
  # - each card has state [up || down || removed] - card's current state
  # - each card has owner [String || nil] - player who currently controls the card
  #

  #
  # rep invariant:
  # - @rows > 0
  # - @columns > 0
  # - @cards array dimensions match board dimensions
  # - every card is a [Hash]
  # - all cards have a value [String]
  # - all cards have a state [up || down || removed]
  # - all cards have an owner [String || nil]
  #

  attr_accessor :rows, :columns, :cards, :queue

  #
  # creates a new board for the game
  # @param [Integer] rows
  # @param [Integer] columns
  # @param [Array[Hash]] cards
  #
  def initialize(rows, columns, cards)
    @rows = rows
    @columns = columns
    @cards = cards
    check_rep
  end

  #
  # checks the rep invariant at startup and after every look/flip/map/watch
  # @raise [StandardError] if any condition is unsatisfied
  #
  def check_rep
    raise 'rows must be > 0' unless @rows.is_a?(Integer) && @rows > 0
    raise 'columns must be > 0' unless @columns.is_a?(Integer) && @columns > 0
    raise 'cards dont match rows' unless @cards.length == @rows
    @cards.each do |row|
      raise 'cards dont match columns' unless row.length == @columns
      row.each do |card|
        raise 'card must be hash' unless card.is_a?(Hash)
        raise 'missing :value' unless card.key?(:value)
        raise 'card value must be nonempty string' unless card[:value].is_a?(String) && !card[:value].empty? && card[:value] !~ /\s/
        raise 'missing :state' unless card.key?(:state)
        raise 'invalid :state' unless card[:state] == 'down' or card[:state] == 'up' or card[:state] == 'removed'
        raise 'missing :owner' unless card.key?(:owner)
      end
    end
  end

  #
  # Make a new board by parsing a file.
  #
  # @param filename [String] path to game board file
  # @return [Board] a new board with size and cards from the file
  # @raise [StandardError] if the file cannot be read or is not a valid game board
  #
  def self.parse_from_file(filename)
    lines = File.readlines(filename, chomp: true)
                .map(&:strip)
                .reject(&:empty?)

    raise "empty txt" if lines.empty?

    header = lines.shift
    raise "wrong dimensions in txt" unless header =~ /^(\d+)x(\d+)$/

    rows = Regexp.last_match(1).to_i
    columns = Regexp.last_match(2).to_i
    raise "wrong card number in txt" unless lines.length == rows * columns

    cards = lines.each_slice(columns).map do |slice|
      slice.map do |v|
        { value: v.dup,
          state: 'down',
          owner: nil,
          matched_by: nil,
          pending_conceal_by: nil,
          mask: v.dup }
        end
    end

    Board.new(rows, columns, cards)
  end

  #
  # pretty-prints the board, for debug only
  # @return [String] board state
  #
  def to_s
    output = +"#{@rows}x#{@columns}\n"
    @cards.each { |row| output << row.map { |c| c[:value] }.join(' ') << "\n" }
    output
  end
end
