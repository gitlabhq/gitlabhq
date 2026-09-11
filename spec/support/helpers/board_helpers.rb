# frozen_string_literal: true

module BoardHelpers
  def click_card(card)
    within card do
      first('.board-card-number').click
      wait_for_requests
    end
  end

  def load_board(board_path)
    visit board_path

    wait_for_requests
  end

  def board_list(index)
    find("[data-testid='board-list']:nth-child(#{index + 1}) .board-list")
  end

  def board_card(list_index, card_index)
    board_list(list_index).all('.board-card', minimum: card_index + 1)[card_index]
  end

  def click_card_and_edit_label
    click_card(card)

    page.within(labels_select) do
      click_button 'Edit'

      wait_for_requests
    end
  end
end
