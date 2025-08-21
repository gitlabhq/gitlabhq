# frozen_string_literal: true

module Features
  module AccessTokenHelpers
    # Remove when we migrate the legacy UI to use initSharedAccessTokenApp
    def active_access_tokens
      find_by_testid('active-tokens')
    end

    def created_access_token
      within_testid('access-token-section') do
        find_by_testid('toggle-visibility-button').click
        find_field('new-access-token').value
      end
    end

    # Keep when we migrate the legacy UI to use initSharedAccessTokenApp
    def new_access_token
      find_by_testid('created-access-token-field').value
    end

    def active_access_tokens_counter
      find_by_testid('active-token-count')
    end

    def access_token_table
      find_by_testid('access-token-table')
    end

    def active_access_tokens_count
      find_by_testid('active-tokens-count')
    end

    def last_used_ip
      find_by_testid('field-last-used')
    end

    def last_used_ips
      find_by_testid('field-last-used-ips')
    end

    def access_token_options
      find_by_testid('access-token-options')
    end
  end
end
