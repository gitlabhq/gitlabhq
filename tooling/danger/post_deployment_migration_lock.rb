# frozen_string_literal: true

require_relative 'database_change_lock_rule'

module Tooling
  module Danger
    class PostDeploymentMigrationLock < DatabaseChangeLockRule
      BACKGROUND_URL = 'https://gitlab.com/gitlab-com/gl-infra/change-lock/-/blob/master/config/changelock.yml'
      SOFT_PCL_DOC_URL = 'https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/change-management/#soft-pcl'
      POST_DEPLOYMENT_MIGRATION_FILE_PATTERN = %r{\A(ee/)?db/post_migrate/}

      private

      def lock_window_label
        'Soft PCL starts at'
      end

      def relevant_change?
        helper.added_files.grep(POST_DEPLOYMENT_MIGRATION_FILE_PATTERN).any?
      end

      def lock_message_template
        <<~MSG
          Merging post-deployment migrations (PDMs) is currently disabled because a soft Production Change Lock (PCL)
          is in effect. PDMs are not executed during a soft PCL, so merging new ones would pile them up and grow the
          backlog that has to run once the PCL ends, increasing the size and risk of that post-PCL migration run.
          After the lock expires, retry this job and danger will pass.

          See change request: %<change_request_issue_url>s

          %<schedule>s
          Locked until: %<end_date>s
          Details: %<details>s
          What is a soft PCL: #{SOFT_PCL_DOC_URL}
          Background: #{BACKGROUND_URL}
        MSG
      end

      def warning_message_template
        <<~MSG
          A post-deployment migration (PDM) lock will be active in %<days_until_lock>s day(s). Starting at %<merge_lock_start_date>s,
          merging new PDMs will be disabled because PDMs are not executed during the upcoming soft Production Change Lock (PCL),
          and merging them anyway would pile them up into a larger, riskier post-PCL migration run.

          See change request: %<change_request_issue_url>s

          %<schedule>s
          Locked until: %<end_date>s
          Details: %<details>s
          What is a soft PCL: #{SOFT_PCL_DOC_URL}
          Background: #{BACKGROUND_URL}
        MSG
      end
    end
  end
end
