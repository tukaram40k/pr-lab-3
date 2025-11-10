require_relative 'board_utils'

class BoardOperations
  #
  # Looks at the current state of the board.
  #
  # @param board [Board] game board
  # @param player_id [String] player identifier
  # @return [String] state of board from player’s perspective
  #
  def look(board, player_id)
    rows = board.rows
    columns = board.columns
    cards = board.cards

    output = +"#{rows}x#{columns}\n"
    cards.each do |row|
      row.each do |c|
        if c[:state] == 'removed'
          output << "none\n"
        elsif c[:owner] == player_id
          output << "my #{c[:value]}\n"
        elsif c[:state] == 'down'
          output << "down\n"
        else
          output << "up #{c[:value]}\n"
        end
      end
    end
    board.check_rep
    output
  end

  #
  # Tries to flip a card on the board, following game rules.
  #
  # @param board [Board]
  # @param player_id [String]
  # @param row [Integer]
  # @param column [Integer]
  # @return [String] board state after flip
  # @raise [GameError] if flip operation fails
  # @raise [WaitForCard] if chosen card is controlled by another player
  #
  def flip(board, player_id, row, column)
    check_bounds(board, row, column)
    card = board.cards[row][column]
    raise GameError, 'no card at that location' if card.nil?

    # determine how many cards the player currently controls
    controlled = controlled_cards(board, player_id)
    case controlled.length
    when 0
      finalize_previous_play(board, player_id)
      handle_first_flip(board, player_id, card, row, column)
    when 1
      handle_second_flip(board, player_id, card, row, column, controlled.first)
    else
      finalize_previous_play(board, player_id)
      handle_first_flip(board, player_id, card, row, column)
    end

    board.check_rep
    look(board, player_id)
  end

  #
  # Modifies the board by replacing each card with f(card),
  # without affecting other game state.
  #
  # @param board [Board]
  # @param player_id [String]
  # @param from_card [String] card to replace
  # @param to_card [String] card to replace with
  # @return [String] board state after replacement
  #
  def map(board, player_id, from_card, to_card)
    # can be async
    board.cards.flatten.each do |c|
      c[:mask] = to_card if c[:value] == from_card
      # sleep(1)
    end

    board.queue.enqueue_look do
      board.cards.flatten.each do |c|
        c[:value] = c[:mask]
      end
    end

    board.check_rep
    look(board, player_id)
  end

  #
  # Watches for board changes, then returns the new board state.
  #
  # @param board [Board]
  # @param player_id [String]
  # @return [String] updated state of board from player’s perspective
  #
  def watch(board, player_id)
    look(board, player_id)
  end

  #
  # transition functions for the flip operation
  #

  #
  # helper method to process a player's first move according to the rules
  # @param board [Board]
  # @param player_id [String]
  # @param card [Hash]
  # @param row [Integer]
  # @param column [Integer]
  # @raise [GameError] if flip operation fails
  # @raise [WaitForCard] if chosen card is controlled by another player
  #
  def handle_first_flip(board, player_id, card, row, column)
    raise GameError, 'no card at that location' if removed?(card)

    case card[:state]
    when 'down'
      # 1-B
      card[:state] = 'up'
      card[:owner] = player_id
    when 'up'
      if card[:owner].nil?
        # 1-C
        card[:owner] = player_id
      elsif card[:owner] != player_id
        # 1-D
        raise WaitForCard.new(row, column, card[:owner])
      end
    else
      raise GameError, "invalid state #{card[:state]}"
    end
  end

  #
  # helper method to process a player's second move according to the rules
  # @param board [Board]
  # @param player_id [String]
  # @param card [Hash]
  # @param row [Integer]
  # @param column [Integer]
  # @param first_info [Hash] first card controlled by the current player
  # @raise [GameError] if flip operation fails
  # @raise [WaitForCard] if chosen card is controlled by another player
  #
  def handle_second_flip(board, player_id, card, row, column, first_info)
    first_card = first_info[:card]

    if removed?(card)
      # 2-A
      relinquish(first_card, player_id)
      raise GameError, 'no card at second-card location; first card relinquished'
    end

    if card[:state] == 'up' && card[:owner]
      # 2-B
      relinquish(first_card, player_id)
      raise GameError, 'second card already controlled; first card relinquished'
    end

    # 2-C
    card[:state] = 'up' if card[:state] == 'down'
    card[:owner] = player_id

    if first_card[:value] == card[:value]
      # 2-D: match
      mark_matched(first_card, card, player_id)
    else
      # 2-E: mismatch
      mark_mismatch(first_card, card, player_id)
    end
  end

  #
  # finishes previous round before making new first flip
  # @param board [Board]
  # @param player_id [String]
  # @return void
  #
  def finalize_previous_play(board, player_id)
    # 3-A and 3-B
    board.cards.flatten.each do |c|
      if c[:matched_by] == player_id
        c[:state] = 'removed'
        c[:owner] = c[:matched_by] = nil
      elsif c[:pending_conceal_by] == player_id && c[:state] == 'up' && c[:owner].nil?
        c[:state] = 'down'
        c[:pending_conceal_by] = nil
      elsif c[:pending_conceal_by] == player_id && c[:state] == 'removed'
        c[:pending_conceal_by] = nil
      end
    end
  end
end
