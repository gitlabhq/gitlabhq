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
      AuthorizedProjectsWorker.new.perform(user_id)
    end
  end

  module ProjectMember
    private

    def execute_project_authorizations_refresh
      AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker.new.perform(project.id, user.id)
    end
  end
end
