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
    @cards = cards.map { |row| row.dup.freeze }.freeze
    check_rep
  end

  def check_rep
    raise 'rows must be > 0' unless @rows.is_a?(Integer) && @rows > 0
    raise 'columns must be > 0' unless @columns.is_a?(Integer) && @columns > 0
    raise 'cards dont match rows' unless @cards.length == @rows
    @cards.each do |row|
      raise 'cards dont match columns' unless row.length == @columns
      row.each do |card|
        raise 'card must be nonempty string' unless card.is_a?(String) && !card.empty? && card !~ /\s/
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

    cards = lines.each_slice(columns).map { |slice| slice.map(&:dup) }

    Board.new(rows, columns, cards)
  end

  # cast board to string
  def to_s
    output = +"#{@rows}x#{@columns}\n"
    @cards.each { |row| output << row.join(' ') << "\n" }
    output
  end
end

# b = Board.parse_from_file(File.expand_path('../boards/ab.txt', File.dirname(__FILE__)))
# puts b