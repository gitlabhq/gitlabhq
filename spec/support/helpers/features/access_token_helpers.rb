# frozen_string_literal: true

module Features
  module AccessTokenHelpers
    def active_access_tokens
      find("[data-testid='active-tokens']")
    end

    def created_access_token
      within('[data-testid=access-token-section]') do
        find('[data-testid=toggle-visibility-button]').click
        find_field('new-access-token').value
      end
    end
  end
end
