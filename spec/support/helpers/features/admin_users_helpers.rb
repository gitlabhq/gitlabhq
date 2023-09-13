# frozen_string_literal: true

module Features
  module AdminUsersHelpers
    def click_user_dropdown_toggle(user_id)
      page.within("[data-testid='user-actions-#{user_id}']") do
        find("[data-testid='user-actions-dropdown-toggle']").click
      end
    end

    def click_action_in_user_dropdown(user_id, action)
      click_user_dropdown_toggle(user_id)

      within find("[data-testid='user-actions-#{user_id}']") do
        find('li button', exact_text: action).click
      end
    end
  end
end
