class WaitForCard < StandardError
  attr_reader :card_key

  def initialize(row, column, owner)
    super("card at #{row},#{column} controlled by #{owner}")
    @card_key = "#{row},#{column}"
  end
end

class GameError < StandardError; end

# helpers
def mark_matched(c1, c2, player_id)
  c1[:matched_by] = player_id
  c2[:matched_by] = player_id
  # both remain owned until removal on next first flip
end

def mark_mismatch(c1, c2, player_id)
  [c1, c2].each do |c|
    c[:owner] = nil
    c[:pending_conceal_by] = player_id
  end
end

def relinquish(card, player_id)
  card[:owner] = nil
  card[:pending_conceal_by] = player_id
end

# utils
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

def check_bounds(board, row, column)
  raise GameError, 'row out of bounds' unless row.between?(0, board.rows - 1)
  raise GameError, 'column out of bounds' unless column.between?(0, board.columns - 1)
end

def removed?(card)
  card.nil? || card[:state] == 'removed'
end