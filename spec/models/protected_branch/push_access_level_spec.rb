# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch::PushAccessLevel do
  it { is_expected.to validate_inclusion_of(:access_level).in_array([Gitlab::Access::MAINTAINER, Gitlab::Access::DEVELOPER, Gitlab::Access::NO_ACCESS]) }

  describe 'associations' do
    it { is_expected.to belong_to(:deploy_key) }
  end

  describe 'validations' do
    it 'is not valid when a record exists with the same access level' do
      protected_branch = create(:protected_branch)
      create(:protected_branch_push_access_level, protected_branch: protected_branch)
      level = build(:protected_branch_push_access_level, protected_branch: protected_branch)

      expect(level).to be_invalid
    end

    it 'is not valid when a record exists with the same access level' do
      protected_branch = create(:protected_branch)
      deploy_key = create(:deploy_key, projects: [protected_branch.project])
      create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)
      level = build(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)

      expect(level).to be_invalid
    end

    it 'checks that a deploy key is enabled for the same project as the protected branch\'s' do
      level = build(:protected_branch_push_access_level, deploy_key: create(:deploy_key))

      expect { level.save! }.to raise_error
      expect(level.errors.full_messages).to contain_exactly('Deploy key is not enabled for this project')
    end
  end
end
