class WaitForCard < StandardError; end
class GameError < StandardError; end

class BoardOperations
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
    output
  end

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

    look(board, player_id)
  end

  private

  # transitions
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
        raise WaitForCard, "card at #{row},#{column} controlled by #{card[:owner]}"
      end
    else
      raise GameError, "invalid state #{card[:state]}"
    end
  end

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
end
