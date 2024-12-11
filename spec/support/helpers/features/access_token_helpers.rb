# frozen_string_literal: true

module Features
  module AccessTokenHelpers
    def active_access_tokens
      find_by_testid('active-tokens')
    end

    def created_access_token
      within_testid('access-token-section') do
        find_by_testid('toggle-visibility-button').click
        find_field('new-access-token').value
      end
    end

    def active_access_tokens_counter
      find_by_testid('active-token-count')
    end
  end
end
