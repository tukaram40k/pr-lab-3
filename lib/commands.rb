require_relative 'board_operations'

#
# String-based commands provided by the Memory Scramble game.
# These are required functions. Do not change names or signatures.
#

BOARD_OPERATIONS = BoardOperations.new

#
# Looks at the current state of the board.
#
# @param board [Board] game board
# @param player_id [String] player identifier
# @return [String] state of board from player’s perspective
#
def look(board, player_id)
  # Implement with glue code only, at most three lines
  BOARD_OPERATIONS.look(board, player_id)
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
  # Implement with glue code only, at most three lines
  BOARD_OPERATIONS.flip(board, player_id, row, column)
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
  # Implement with glue code only, at most three lines
  BOARD_OPERATIONS.map(board, player_id, &f)
end

#
# Watches for board changes, then returns the new board state.
#
# @param board [Board]
# @param player_id [String]
# @return [String] updated state of board from player’s perspective
#
def watch(board, player_id)
  # Implement with glue code only, at most three lines
  BOARD_OPERATIONS.watch(board, player_id)
end
