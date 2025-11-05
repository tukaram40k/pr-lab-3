require 'thread'

#
# TODO specification
# Mutable and concurrency safe.
#
class Board
  # TODO fields

  # Abstraction function:
  #   TODO
  # Representation invariant:
  #   TODO
  # Safety from rep exposure:
  #   TODO

  def initialize
    # TODO initialize board representation
    # Use @lock = Mutex.new for thread-safety if needed
    @lock = Mutex.new
  end

  # TODO: implement checkRep (representation invariant check)
  def check_rep
    # TODO
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
    raise "file not found: #{filename}" unless File.exist?(filename)

    # Placeholder: just create an empty board
    Board.new
  end
end
