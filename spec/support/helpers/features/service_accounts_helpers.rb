# frozen_string_literal: true

module Features
  module ServiceAccountsHelpers
    def open_service_account_options
      find('[data-testid="cell-options"] button').click
    end

    def navigate_to_token_management(path)
      visit path

      open_service_account_options
      click_button s_('ServiceAccounts|Manage access tokens')
    end
  end
end
