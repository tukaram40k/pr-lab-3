require 'thread'

class Board
  attr_accessor :rows, :columns, :cards

  # Abstraction function:
  #   TODO
  # Representation invariant:
  #   TODO
  # Safety from rep exposure:
  #   TODO

  def initialize(rows, columns, cards)
    @rows = rows
    @columns = columns
    @cards = cards
    check_rep
  end

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
        raise 'invalid :state' unless card[:state] == 'down'
        raise 'missing :owner' unless card.key?(:owner)
        raise 'invalid :owner' unless card[:owner].nil?
      end
    end
  end

  # TODO: other methods

  #
  # Make a new board by parsing a file.
  #
  # @param filename [String] path to game board file
  # @return [Board] a new board with size and cards from the file
  # @raise [RuntimeError] if the file cannot be read or is not a valid game board
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
      slice.map { |v| { value: v.dup, state: 'down', owner: nil } }
    end

    Board.new(rows, columns, cards)
  end

  def look(player_id)
    output = +"#{@rows}x#{@columns}\n"
    @cards.each do |row|
      row.each do |c|
        if c[:state] == 'removed'
          output << "none\n"
        else
          if c[:owner] == player_id
            output << "my #{c[:value]}\n"
          else
            if c[:state] == 'down'
              output << "down\n"
            else
              output << "up #{c[:value]}\n"
            end
          end
        end
      end
    end
    output
  end

  def flip(player_id, row, column)

  end

  # cast board to string
  def to_s
    output = +"#{@rows}x#{@columns}\n"
    @cards.each { |row| output << row.map { |c| c[:value] }.join(' ') << "\n" }
    output
  end
end

# b = Board.parse_from_file(File.expand_path('../boards/zoom.txt', File.dirname(__FILE__)))
# puts b
# b.cards[0][0][:owner] = 'e'
# b.cards[0][1][:state] = 'removed'
# b.cards[1][0][:state] = 'up'
# puts b.look('e')