require 'minitest/autorun'
require_relative '../lib/board/board'
require_relative '../lib/commands'

class LookTest < Minitest::Test
  def setup
    @board = Board.parse_from_file('boards/ab.txt')
  end

  def test_resulting_board
    result = look(@board, 'player1')
    assert_includes result, '5x5'
    assert_equal 26, result.lines.count
  end

  def test_card_states
    id = 'player123'
    @board.cards[0][0][:state] = 'up'
    @board.cards[1][1][:state] = 'removed'
    @board.cards[0][1][:value] = 'V'
    @board.cards[0][1][:owner] = id

    result = look(@board, id)
    lines = result.lines.map(&:chomp)

    assert_equal 26, result.lines.count
    assert_equal 'up A', lines[1]
    assert_equal 'none', lines[7]
    assert_equal 'my V', lines[2]
  end
end