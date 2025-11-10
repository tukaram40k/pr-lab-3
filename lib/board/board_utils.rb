#
# exception raised when waiting for a card controlled by another player
#
class WaitForCard < StandardError
  attr_reader :card_key

  def initialize(row, column, owner)
    super("card at #{row},#{column} controlled by #{owner}")
    @card_key = "#{row},#{column}"
  end
end

#
# exception raised when flip operation fails
#
class GameError < StandardError; end

#
# helpers
#

#
# checks if two cards are a match and marks them
# @param c1 [Hash] card 1
# @param c2 [Hash] card 2
# @param player_id [String] card owner
#
def mark_matched(c1, c2, player_id)
  c1[:matched_by] = player_id
  c2[:matched_by] = player_id
  # both remain owned until removal on next first flip
end

#
# checks if two cards are not a match and marks them
# @param c1 [Hash] card 1
# @param c2 [Hash] card 2
# @param player_id [String] card owner
#
def mark_mismatch(c1, c2, player_id)
  [c1, c2].each do |c|
    c[:owner] = nil
    c[:pending_conceal_by] = player_id
  end
end

#
# releases the card and marks it to be turned down
# @param card [Hash] card
# @param player_id [String] card owner
#
def relinquish(card, player_id)
  card[:owner] = nil
  card[:pending_conceal_by] = player_id
end

#
# utils
#

#
# gets list of cards controlled by current player
# @param board [Board]
# @param player_id [String] card owner
# @return [Array[Hash]] array of card hashes
#
def controlled_cards(board, player_id)
  cards = []
  board.cards.each_with_index do |row, ri|
    row.each_with_index do |c, ci|
      next unless c[:state] == 'up' && c[:owner] == player_id
      cards << { row: ri, col: ci, card: c }
    end
  end
  cards
end

#
# checks if current position is within bounds
# @param board [Board]
# @param row [Integer]
# @param column [Integer]
# @raise [GameError] if position is out of bounds
#
def check_bounds(board, row, column)
  raise GameError, 'row out of bounds' unless row.between?(0, board.rows - 1)
  raise GameError, 'column out of bounds' unless column.between?(0, board.columns - 1)
end

#
# checks if current card is removed
# @param card [Hash]
# @return [Boolean]
#
def removed?(card)
  card.nil? || card[:state] == 'removed'
end