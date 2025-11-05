require_relative 'board'

#
# String-based commands provided by the Memory Scramble game.
# These are required functions. Do not change names or signatures.
#

#
# Looks at the current state of the board.
#
# @param board [Board] game board
# @param player_id [String] player identifier
# @return [String] state of board from player’s perspective
#
def look(board, player_id)
  raise 'look function not implemented'
  # Implement with glue code only, at most three lines
end

#
# Tries to flip a card on the board, following game rules.
#
# @param board [Board]
# @param player_id [String]
# @param row [Integer]
# @param column [Integer]
# @return [String] board state after flip
# @raise [RuntimeError] if flip operation fails
#
def flip(board, player_id, row, column)
  raise 'flip function not implemented'
  # Implement with glue code only, at most three lines
end

#
# Modifies the board by replacing each card with f(card),
# without affecting other game state.
#
# @param board [Board]
# @param player_id [String]
# @param f [Proc] function from card -> new card
# @return [String] board state after replacement
#
def map(board, player_id, &f)
  raise 'map function not implemented'
  # Implement with glue code only, at most three lines
end

#
# Watches for board changes, then returns the new board state.
#
# @param board [Board]
# @param player_id [String]
# @return [String] updated state of board from player’s perspective
#
def watch(board, player_id)
  raise 'watch function not implemented'
  # Implement with glue code only, at most three lines
end
