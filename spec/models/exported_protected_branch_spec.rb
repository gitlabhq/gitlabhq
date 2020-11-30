# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportedProtectedBranch do
  describe 'Associations' do
    it { is_expected.to have_many(:push_access_levels) }
  end

  describe '.push_access_levels' do
    it 'returns the correct push access levels' do
      exported_branch = create(:exported_protected_branch, :developers_can_push)
      deploy_key = create(:deploy_key)
      create(:deploy_keys_project, :write_access, project: exported_branch.project, deploy_key: deploy_key )
      create(:protected_branch_push_access_level, protected_branch: exported_branch, deploy_key: deploy_key)
      dev_push_access_level = exported_branch.push_access_levels.first

      expect(exported_branch.push_access_levels).to contain_exactly(dev_push_access_level)
    end
  end
end
