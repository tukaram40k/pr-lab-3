require 'minitest/autorun'
require_relative '../lib/board/board'
require_relative '../lib/commands'
require_relative '../lib/controllers/request_queue'

class WatchTest < Minitest::Test
  def setup
    @board = Board.parse_from_file('boards/ab.txt')
    @board.queue = RequestQueue.new
    @id = 'player1'
  end

  def test_resulting_board
    result = look(@board, @id)

    assert_includes result, '5x5'
    assert_equal 26, result.lines.count
  end

  def test_watch
    thread = Thread.new do
      watch(@board, @id)
    end

    flip(@board, @id, 0, 1)
    result = thread.value

    assert_includes result, 'my B'
  end
end