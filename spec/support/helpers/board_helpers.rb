# frozen_string_literal: true

module BoardHelpers
  def click_card(card)
    within card do
      first('.board-card-number').click
      wait_for_requests
    end
  end
end
