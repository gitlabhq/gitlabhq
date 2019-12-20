# frozen_string_literal: true

require 'spec_helper'

describe BlobPolicy do
  include_context 'ProjectPolicyTable context'
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository, project_level) }
  let(:user) { create_user_from_membership(project, membership) }
  let(:blob) { project.repository.blob_at(SeedRepo::FirstCommit::ID, 'README.md') }

  subject(:policy) { described_class.new(user, blob) }

  where(:project_level, :feature_access_level, :membership, :expected_count) do
    permission_table_for_guest_feature_access_and_non_private_project_only
  end

  with_them do
    it "grants permission" do
      update_feature_access_level(project, feature_access_level)

      if expected_count == 1
        expect(policy).to be_allowed(:read_blob)
      else
        expect(policy).to be_disallowed(:read_blob)
      end
    end
  end
end
