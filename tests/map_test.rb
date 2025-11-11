require 'minitest/autorun'
require_relative '../lib/board/board'
require_relative '../lib/commands'
require_relative '../lib/controllers/request_queue'

class MapTest < Minitest::Test
  def setup
    @board = Board.parse_from_file('boards/ab.txt')
    @board2 = Board.parse_from_file('boards/ab.txt')
    @board.queue = RequestQueue.new
    @id = 'player1'
  end

  def test_resulting_board
    result = look(@board, @id)
    result2 = look(@board2, @id)

    assert_includes result, '5x5'
    assert_equal 26, result.lines.count
    assert_includes result2, '5x5'
    assert_equal 26, result2.lines.count
  end

  def test_card_replacement
    replacement = 'ЪУЪ'
    map(@board, @id, 'A', replacement)

    @board2.cards.flatten.map do | card |
      if card[:value] == 'A'
        card[:value] = replacement
        card[:mask] = replacement
      end
    end

    assert_equal @board.cards, @board2.cards
  end
end