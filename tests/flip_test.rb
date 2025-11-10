require 'minitest/autorun'
require_relative '../lib/commands'
require_relative '../lib/board/board_operations'
require_relative '../lib/board/board_utils'

class GameError < StandardError; end
class WaitForCard < StandardError
  attr_reader :row, :column, :owner
  def initialize(row, column, owner)
    @row = row
    @column = column
    @owner = owner
    super("Wait for card at #{row},#{column} owned by #{owner}")
  end
end

class MockBoard
  attr_reader :rows, :columns, :cards

  def initialize(rows, columns, cards)
    @rows = rows
    @columns = columns
    @cards = cards
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
        raise 'card value must be nonempty string' unless (card[:value].is_a?(String) or card[:value].is_a?(Integer))
        raise 'missing :state' unless card.key?(:state)
        raise 'invalid :state' unless card[:state] == 'down' or card[:state] == 'up' or card[:state] == 'removed'
        raise 'missing :owner' unless card.key?(:owner)
      end
    end
  end
end

class FlipTest < Minitest::Test
  def setup
    @player_id = 1
    @other_player_id = 2
    @bop = BoardOperations.new

    @down_card = { state: 'down', owner: nil, value: 5, matched_by: nil, pending_conceal_by: nil }
    @up_unowned_card = { state: 'up', owner: nil, value: 5, matched_by: nil, pending_conceal_by: nil }
    @up_my_card = { state: 'up', owner: @player_id, value: 5, matched_by: nil, pending_conceal_by: nil }
    @up_other_card = { state: 'up', owner: @other_player_id, value: 5, matched_by: nil, pending_conceal_by: nil }
    @removed_card = { state: 'removed', owner: nil, value: 5, matched_by: nil, pending_conceal_by: nil }
  end

  def test_check_bounds_valid
    cards = [[@down_card]]
    board = MockBoard.new(1, 1, cards)

    assert_nil check_bounds(board, 0, 0)
  end

  def test_check_bounds_invalid_row
    cards = [[@down_card]]
    board = MockBoard.new(1, 1, cards)

    assert_raises(GameError) { check_bounds(board, 1, 0) }
  end

  def test_check_bounds_invalid_column
    cards = [[@down_card]]
    board = MockBoard.new(1, 1, cards)

    assert_raises(GameError) { check_bounds(board, 0, 1) }
  end

  def test_removed?
    assert removed?(@removed_card)
    refute removed?(@down_card)
  end

  def test_controlled_cards
    cards = [
      [@up_my_card, @down_card],
      [@up_other_card, @up_my_card]
    ]
    board = MockBoard.new(2, 2, cards)

    controlled = controlled_cards(board, @player_id)
    assert_equal 2, controlled.length
    assert_includes controlled.map { |c| c[:card] }, @up_my_card
  end

  def test_handle_first_flip_down_card
    card = @down_card.dup
    @bop.handle_first_flip(@board, @player_id, card, 0, 0)

    assert_equal 'up', card[:state]
    assert_equal @player_id, card[:owner]
  end

  def test_handle_first_flip_up_unowned_card
    card = @up_unowned_card.dup
    @bop.handle_first_flip(@board, @player_id, card, 0, 0)

    assert_equal @player_id, card[:owner]
  end

  def test_handle_first_flip_up_other_player_card
    card = @up_other_card.dup

    assert_raises(WaitForCard) do
      @bop.handle_first_flip(@board, @player_id, card, 0, 0)
    end
  end

  def test_handle_first_flip_removed_card
    assert_raises(GameError) do
      @bop.handle_first_flip(@board, @player_id, @removed_card, 0, 0)
    end
  end

  def test_handle_second_flip_removed_second_card
    first_card = @up_my_card.dup
    second_card = @removed_card.dup
    first_info = { card: first_card }

    assert_raises(GameError) do
      @bop.handle_second_flip(@board, @player_id, second_card, 0, 0, first_info)
    end

    assert_nil first_card[:owner]  # First card should be relinquished
  end

  def test_handle_second_flip_already_controlled_second_card
    first_card = @up_my_card.dup
    second_card = @up_other_card.dup
    first_info = { card: first_card }

    assert_raises(GameError) do
      @bop.handle_second_flip(@board, @player_id, second_card, 0, 0, first_info)
    end

    assert_nil first_card[:owner]  # First card should be relinquished
  end

  def test_handle_second_flip_match
    first_card = @up_my_card.dup
    second_card = @down_card.dup
    second_card[:value] = first_card[:value]
    first_info = { card: first_card }

    @bop.handle_second_flip(@board, @player_id, second_card, 0, 0, first_info)

    assert_equal 'up', second_card[:state]
    assert_equal @player_id, second_card[:owner]
  end

  def test_handle_second_flip_mismatch
    first_card = @up_my_card.dup
    second_card = @down_card.dup
    second_card[:value] = first_card[:value] + 1
    first_info = { card: first_card }

    @bop.handle_second_flip(@board, @player_id, second_card, 0, 0, first_info)

    assert_equal 'up', second_card[:state]
    assert_nil second_card[:owner]
  end

  # Test finalize_previous_play scenarios
  def test_finalize_previous_play_matched_cards
    matched_card = { state: 'up', owner: @player_id, value: 5, matched_by: @player_id, pending_conceal_by: nil }
    cards = [[matched_card]]
    board = MockBoard.new(1, 1, cards)

    @bop.finalize_previous_play(board, @player_id)

    assert_equal 'removed', cards[0][0][:state]
    assert_nil cards[0][0][:owner]
    assert_nil cards[0][0][:matched_by]
  end

  def test_finalize_previous_play_pending_conceal
    pending_card = { state: 'up', owner: nil, value: 5, matched_by: nil, pending_conceal_by: @player_id }
    cards = [[pending_card]]
    board = MockBoard.new(1, 1, cards)

    @bop.finalize_previous_play(board, @player_id)

    assert_equal 'down', cards[0][0][:state]
    assert_nil cards[0][0][:pending_conceal_by]
  end

  def test_finalize_previous_play_pending_conceal_removed
    pending_card = { state: 'removed', owner: nil, value: 5, matched_by: nil, pending_conceal_by: @player_id }
    cards = [[pending_card]]
    board = MockBoard.new(1, 1, cards)

    @bop.finalize_previous_play(board, @player_id)

    assert_nil cards[0][0][:pending_conceal_by]
  end

  def test_flip_first_card_down
    cards = [[@down_card.dup]]
    board = MockBoard.new(1, 1, cards)

    result = flip(board, @player_id, 0, 0)

    assert_equal 'up', cards[0][0][:state]
    assert_equal @player_id, cards[0][0][:owner]
    assert_includes result, "1x1"
  end

  def test_flip_first_card_up_unowned
    cards = [[@up_unowned_card.dup]]
    board = MockBoard.new(1, 1, cards)

    result = flip(board, @player_id, 0, 0)

    assert_equal @player_id, cards[0][0][:owner]
    assert_includes result, "1x1"
  end

  def test_flip_second_card_match
    first_card = @up_my_card.dup
    second_card = @down_card.dup
    second_card[:value] = first_card[:value]
    cards = [[first_card, second_card]]
    board = MockBoard.new(1, 2, cards)

    def board.controlled_cards(player_id)
      [{ card: @cards[0][0] }]
    end

    result = flip(board, @player_id, 0, 1)

    assert_equal @player_id, cards[0][1][:owner]
    assert_includes result, "1x2"
  end

  def test_flip_out_of_bounds
    cards = [[@down_card]]
    board = MockBoard.new(1, 1, cards)

    assert_raises(GameError) do
      flip(board, @player_id, 2, 2)
    end
  end

  def test_flip_nil_card
    cards = [[nil]]
    board = MockBoard.new(1, 1, cards)

    assert_raises(GameError) do
      flip(board, @player_id, 0, 0)
    end
  end

  def test_flip_removed_card
    cards = [[@removed_card]]
    board = MockBoard.new(1, 1, cards)

    assert_raises(GameError) do
      flip(board, @player_id, 0, 0)
    end
  end

  def test_flip_with_previous_play_finalization
    matched_card = { state: 'up', owner: @player_id, value: 5, matched_by: @player_id, pending_conceal_by: nil }
    new_card = @down_card.dup
    cards = [[matched_card, new_card]]
    board = MockBoard.new(1, 2, cards)

    def board.controlled_cards(player_id)
      [{ card: @cards[0][0] }, { card: @cards[0][0] }]  # Mock having 2 controlled cards
    end

    result = flip(board, @player_id, 0, 1)

    assert_equal 'up', cards[0][0][:state]
    assert_equal 'up', cards[0][1][:state]
    assert_equal @player_id, cards[0][1][:owner]
  end

  def test_relinquish
    card = @up_my_card.dup
    relinquish(card, @player_id)

    assert_nil card[:owner]
  end
end