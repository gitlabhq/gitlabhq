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

  def drag(selector: '.board-list', list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, perform_drop: true)
    inspect_requests(inject_headers: { 'X-GITLAB-DISABLE-SQL-QUERY-LIMIT' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/323426' }) do
      # ensure there is enough horizontal space for four board lists
      resize_window(2000, 800)

      drag_to(
        selector: selector,
        scrollable: '#board-app',
        list_from_index: list_from_index,
        from_index: from_index,
        to_index: to_index,
        list_to_index: list_to_index,
        perform_drop: perform_drop
      )
    end

    wait_for_requests
  end
end
