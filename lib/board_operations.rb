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
        else
          if c[:owner] == player_id
            output << "my #{c[:value]}\n"
          else
            if c[:state] == 'down'
              output << "down\n"
            else
              output << "up #{c[:value]}\n"
            end
          end
        end
      end
    end
    output
  end

  def flip(board, player_id, row, column)
    cards = board.cards

    current_card = cards[row][column]
    current_state = current_card[:state]
    current_owner = current_card[:owner]

    if current_state == 'down' and current_owner == nil
      cards[row][column][:state] = 'up'
      cards[row][column][:owner] = player_id
    end

    look(board, player_id)
  end

  def map(board, player_id, &f)
    raise 'map not implemented'
  end

  def watch(board, player_id)
    raise 'watch not implemented'
  end
end