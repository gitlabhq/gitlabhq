# frozen_string_literal: true

require_relative 'database_change_lock_rule'

module Tooling
  module Danger
    class DatabaseUpgradeDdlLock < DatabaseChangeLockRule
      BACKGROUND_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/579388'
      SCHEMA_FILE_PATTERN = %r{\Adb/structure\.sql}

      private

      def lock_window_label
        'Maintenance starts at'
      end

      def relevant_change?
        helper.all_changed_files.grep(SCHEMA_FILE_PATTERN).any?
      end

      def lock_message_template
        <<~MSG
          Merging migrations that change schema is currently disabled while a major database upgrade is
          performed. After the lock expires, retry this job and danger will pass.

          See change request: %<change_request_issue_url>s

          %<schedule>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end

      def warning_message_template
        <<~MSG
          A database upgrade lock will be active in %<days_until_lock>s day(s). Starting at %<merge_lock_start_date>s, merging
          migrations that changes the schema (DDL) will be disabled. The maintenance window is scheduled for %<maintenance_start_date>s,
          but merges are blocked %<merge_buffer_days>s day(s) earlier to allow time for deployment ahead of the upgrade.

          See change request: %<change_request_issue_url>s

          %<schedule>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end
    end
  end
end
