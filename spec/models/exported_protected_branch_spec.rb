# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportedProtectedBranch, feature_category: :source_code_management do
  describe 'Associations' do
    it { is_expected.to have_many(:push_access_levels) }
  end

  describe '.push_access_levels' do
    it 'returns the correct push access levels' do
      exported_branch = create(:exported_protected_branch, :developers_can_push)
      project = exported_branch.project
      user = create(:user, guest_of: project)
      deploy_key = create(:deploy_key, user: user, write_access_to: project)
      deploy_key_access_level =
        create(:protected_branch_push_access_level, protected_branch: exported_branch, deploy_key: deploy_key)

      expect(exported_branch.push_access_levels).not_to include(deploy_key_access_level)
    end
  end
end
