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

  def click_card_and_edit_label
    click_card(card)

    page.within(labels_select) do
      click_button 'Edit'

      wait_for_requests
    end
  end
end
