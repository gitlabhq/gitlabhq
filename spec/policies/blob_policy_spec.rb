# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobPolicy do
  include_context 'ProjectPolicyTable context'
  include ProjectHelpers
  include UserHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:user) { create_user_from_membership(project, membership) }
  let(:blob) { project.repository.blob_at(SeedRepo::FirstCommit::ID, 'README.md') }

  subject(:policy) { described_class.new(user, blob) }

  where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
    permission_table_for_guest_feature_access_and_non_private_project_only
  end

  with_them do
    it 'grants permission' do
      enable_admin_mode!(user) if admin_mode
      update_feature_access_level(
        project,
        feature_access_level,
        visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s)
      )

      if expected_count == 1
        expect(policy).to be_allowed(:read_blob)
      else
        expect(policy).to be_disallowed(:read_blob)
      end
    end
  end
end
