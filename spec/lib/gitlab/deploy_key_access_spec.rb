# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DeployKeyAccess do
  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_key) { create(:deploy_key, user: user) }

  let(:project) { create(:project, :repository) }
  let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project) }

  subject(:access) { described_class.new(deploy_key, container: project) }

  before do
    project.add_guest(user)
    create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key)
  end

  describe '#can_create_tag?' do
    context 'push tag that matches a protected tag pattern via a deploy key' do
      it 'still pushes that tag' do
        create(:protected_tag, project: project, name: 'v*')

        expect(access.can_create_tag?('v0.1.2')).to be_truthy
      end
    end
  end

  describe '#can_push_for_ref?' do
    context 'push to a protected branch of this project via a deploy key' do
      before do
        create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)
      end

      context 'when the project has active deploy key owned by this user' do
        it 'returns true' do
          expect(access.can_push_for_ref?(protected_branch.name)).to be_truthy
        end
      end

      context 'when the project has active deploy keys, but not by this user' do
        let(:deploy_key) { create(:deploy_key, user: create(:user)) }

        it 'returns false' do
          expect(access.can_push_for_ref?(protected_branch.name)).to be_falsey
        end
      end

      context 'when there is another branch no one can push to' do
        let(:another_branch) { create(:protected_branch, :no_one_can_push, name: 'another_branch', project: project) }

        it 'returns false when trying to push to that other branch' do
          expect(access.can_push_for_ref?(another_branch.name)).to be_falsey
        end

        context 'and the deploy key added for the first protected branch is also added for this other branch' do
          it 'returns true for both protected branches' do
            create(:protected_branch_push_access_level, protected_branch: another_branch, deploy_key: deploy_key)

            expect(access.can_push_for_ref?(protected_branch.name)).to be_truthy
            expect(access.can_push_for_ref?(another_branch.name)).to be_truthy
          end
        end
      end
    end
  end
end
