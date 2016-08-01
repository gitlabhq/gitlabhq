require 'spec_helper'

describe Gitlab::UserAccess, lib: true do
  let(:access) { Gitlab::UserAccess.new(user, project: project) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'can_push_to_branch?' do
    describe 'push to none protected branch' do
      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?('random_branch')).to be_falsey
      end
    end

    describe 'push to empty project' do
      let(:empty_project) { create(:project_empty_repo) }
      let(:project_access) { Gitlab::UserAccess.new(user, project: empty_project) }

      it 'returns true if user is master' do
        empty_project.team << [user, :master]

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end

      it 'returns false if user is developer and project is fully protected' do
        empty_project.team << [user, :developer]
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_FULL)

        expect(project_access.can_push_to_branch?('master')).to be_falsey
      end

      it 'returns false if user is developer and it is not allowed to push new commits but can merge into branch' do
        empty_project.team << [user, :developer]
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(project_access.can_push_to_branch?('master')).to be_falsey
      end

      it 'returns true if user is developer and project is unprotected' do
        empty_project.team << [user, :developer]
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end

      it 'returns true if user is developer and project grants developers permission' do
        empty_project.team << [user, :developer]
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end
    end

    describe 'push to protected branch' do
      let(:branch) { create :protected_branch, project: project }

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end
    end

    describe 'push to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_push, project: project
      end

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

    describe 'merge to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_merge, project: project
      end

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_merge_to_branch?(@branch.name)).to be_falsey
      end
    end

  end
end
