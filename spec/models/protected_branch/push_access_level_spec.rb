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

  describe '#check_access' do
    let_it_be(:project) { create(:project) }
    let_it_be(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:deploy_key) { create(:deploy_key, user: user) }

    let!(:deploy_keys_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key, can_push: can_push) }
    let(:can_push) { true }

    before_all do
      project.add_maintainer(user)
    end

    context 'when this push_access_level is tied to a deploy key' do
      let(:push_access_level) { create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key) }

      context 'when the deploy key is among the active keys for this project' do
        specify do
          expect(push_access_level.check_access(user)).to be_truthy
        end
      end

      context 'when the deploy key is not among the active keys of this project' do
        let(:can_push) { false }

        it 'is false' do
          expect(push_access_level.check_access(user)).to be_falsey
        end
      end
    end
  end

  describe '#type' do
    let(:push_level_access) { build(:protected_branch_push_access_level) }

    it 'returns :deploy_key when a deploy key is tied to the protected branch' do
      push_level_access.deploy_key = create(:deploy_key)

      expect(push_level_access.type).to eq(:deploy_key)
    end

    it 'returns :role by default' do
      expect(push_level_access.type).to eq(:role)
    end
  end
end
