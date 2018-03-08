require 'spec_helper'

describe Gitlab::UserAccess do
  include ProjectForksHelper

  let(:access) { described_class.new(user, project: project) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#can_push_to_branch?' do
    describe 'push to none protected branch' do
      it 'returns true if user is a master' do
        project.add_master(user)

        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?('random_branch')).to be_falsey
      end
    end

    describe 'push to empty project' do
      let(:empty_project) { create(:project_empty_repo) }
      let(:project_access) { described_class.new(user, project: empty_project) }

      it 'returns true if user is master' do
        empty_project.add_master(user)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end

      it 'returns false if user is developer and project is fully protected' do
        empty_project.add_developer(user)
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_FULL)

        expect(project_access.can_push_to_branch?('master')).to be_falsey
      end

      it 'returns false if user is developer and it is not allowed to push new commits but can merge into branch' do
        empty_project.add_developer(user)
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(project_access.can_push_to_branch?('master')).to be_falsey
      end

      it 'returns true if user is developer and project is unprotected' do
        empty_project.add_developer(user)
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end

      it 'returns true if user is developer and project grants developers permission' do
        empty_project.add_developer(user)
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end
    end

    describe 'push to protected branch' do
      let(:branch) { create :protected_branch, project: project, name: "test" }
      let(:not_existing_branch) { create :protected_branch, :developers_can_merge, project: project }

      it 'returns true if user is a master' do
        project.add_master(user)

        expect(access.can_push_to_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if branch does not exist' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(not_existing_branch.name)).to be_falsey
      end
    end

    describe 'push to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_push, project: project
      end

      it 'returns true if user is a master' do
        project.add_master(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

    describe 'allowing pushes to maintainers of forked projects' do
      let(:canonical_project) { create(:project, :public, :repository) }
      let(:project) { fork_project(canonical_project, create(:user), repository: true) }

      before do
        create(
          :merge_request,
          target_project: canonical_project,
          source_project: project,
          source_branch: 'awesome-feature',
          allow_maintainer_to_push: true
        )
      end

      it 'allows users that have push access to the canonical project to push to the MR branch' do
        canonical_project.add_developer(user)

        expect(access.can_push_to_branch?('awesome-feature')).to be_truthy
      end

      it 'does not allow the user to push to other branches' do
        canonical_project.add_developer(user)

        expect(access.can_push_to_branch?('master')).to be_falsey
      end

      it 'does not allow the user to push if he does not have push access to the canonical project' do
        canonical_project.add_guest(user)

        expect(access.can_push_to_branch?('awesome-feature')).to be_falsey
      end
    end

    describe 'merge to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_merge, project: project
      end

      it 'returns true if user is a master' do
        project.add_master(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_falsey
      end
    end
  end

  describe '#can_create_tag?' do
    describe 'push to none protected tag' do
      it 'returns true if user is a master' do
        project.add_user(user, :master)

        expect(access.can_create_tag?('random_tag')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?('random_tag')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?('random_tag')).to be_falsey
      end
    end

    describe 'push to protected tag' do
      let(:tag) { create(:protected_tag, project: project, name: "test") }
      let(:not_existing_tag) { create :protected_tag, project: project }

      it 'returns true if user is a master' do
        project.add_user(user, :master)

        expect(access.can_create_tag?(tag.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?(tag.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?(tag.name)).to be_falsey
      end
    end

    describe 'push to protected tag if allowed for developers' do
      before do
        @tag = create(:protected_tag, :developers_can_create, project: project)
      end

      it 'returns true if user is a master' do
        project.add_user(user, :master)

        expect(access.can_create_tag?(@tag.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?(@tag.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?(@tag.name)).to be_falsey
      end
    end
  end

  describe '#can_delete_branch?' do
    describe 'delete unprotected branch' do
      it 'returns true if user is a master' do
        project.add_user(user, :master)

        expect(access.can_delete_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_delete_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_delete_branch?('random_branch')).to be_falsey
      end
    end

    describe 'delete protected branch' do
      let(:branch) { create(:protected_branch, project: project, name: "test") }

      it 'returns true if user is a master' do
        project.add_user(user, :master)

        expect(access.can_delete_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_delete_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_delete_branch?(branch.name)).to be_falsey
      end
    end
  end
end
