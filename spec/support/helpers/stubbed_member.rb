# frozen_string_literal: true

# Extend the ProjectMember & GroupMember class with the ability to
# to run project_authorizations refresh jobs inline.

# This is needed so that calls like `group.add_member(user, access_level)` or `create(:project_member)`
# in the specs can be run without including `:sidekiq_inline` trait.
module StubbedMember
  extend ActiveSupport::Concern

  module Member
    private

    def refresh_member_authorized_projects
      # In stubbed_member the original methods stubbed would call .perform_async
      # so the affected workers would not be in a transaction in a non-test environment.
      Gitlab::ExclusiveLease.skipping_transaction_check do
        AuthorizedProjectsWorker.new.perform(user_id)
      end
    end
  end

  module ProjectMember
    private

    def execute_project_authorizations_refresh
      # In stubbed_member the original methods stubbed would call .perform_async
      # so the affected workers would not be in a transaction in a non-test environment.
      Gitlab::ExclusiveLease.skipping_transaction_check do
        AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker.new.perform(project.id, user.id)
      end
    end
  end
end
