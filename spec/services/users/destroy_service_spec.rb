require 'spec_helper'

describe Users::DestroyService do
  describe "Deletes a user and all their personal projects" do
    let!(:user)      { create(:user) }
    let!(:admin)     { create(:admin) }
    let!(:namespace) { user.namespace }
    let!(:project)   { create(:project, namespace: namespace) }
    let(:service)    { described_class.new(admin) }
    let(:gitlab_shell) { Gitlab::Shell.new }

    context 'no options are given' do
      it 'deletes the user' do
        user_data = service.execute(user)

        expect { user_data['email'].to eq(user.email) }
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Namespace.find(namespace.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will delete the project' do
        expect_any_instance_of(Projects::DestroyService).to receive(:execute).once

        service.execute(user)
      end
    end

    context 'projects in pending_delete' do
      before do
        project.pending_delete = true
        project.save
      end

      it 'destroys a project in pending_delete' do
        expect_any_instance_of(Projects::DestroyService).to receive(:execute).once

        service.execute(user)

        expect { Project.find(project.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "a deleted user's issues" do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
      end

      context "for an issue the user was assigned to" do
        let!(:issue) { create(:issue, project: project, assignees: [user]) }

        before do
          service.execute(user)
        end

        it 'does not delete issues the user is assigned to' do
          expect(Issue.find_by_id(issue.id)).to be_present
        end

        it 'migrates the issue so that it is "Unassigned"' do
          migrated_issue = Issue.find_by_id(issue.id)

          expect(migrated_issue.assignees).to be_empty
        end
      end
    end

    context "a deleted user's merge_requests" do
      let(:project) { create(:project, :repository) }

      before do
        project.add_developer(user)
      end

      context "for an merge request the user was assigned to" do
        let!(:merge_request) { create(:merge_request, source_project: project, assignee: user) }

        before do
          service.execute(user)
        end

        it 'does not delete merge requests the user is assigned to' do
          expect(MergeRequest.find_by_id(merge_request.id)).to be_present
        end

        it 'migrates the merge request so that it is "Unassigned"' do
          migrated_merge_request = MergeRequest.find_by_id(merge_request.id)

          expect(migrated_merge_request.assignee).to be_nil
        end
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user)
      end

      it 'does not delete the user' do
        expect(User.find(user.id)).to eq user
      end
    end

    context "deletions with solo owned groups" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Project.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "deletion permission checks" do
      it 'does not delete the user when user is not an admin' do
        other_user = create(:user)

        expect { described_class.new(other_user).execute(user) }.to raise_error(Gitlab::Access::AccessDeniedError)
        expect(User.exists?(user.id)).to be(true)
      end

      it 'allows admins to delete anyone' do
        described_class.new(admin).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end

      it 'allows users to delete their own account' do
        described_class.new(user).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end
    end

    context "migrating associated records" do
      let!(:issue)     { create(:issue, author: user) }

      it 'delegates to the `MigrateToGhostUser` service to move associated records to the ghost user' do
        expect_any_instance_of(Users::MigrateToGhostUserService).to receive(:execute).once.and_call_original

        service.execute(user)

        expect(issue.reload.author).to be_ghost
      end

      it 'does not run `MigrateToGhostUser` if hard_delete option is given' do
        expect_any_instance_of(Users::MigrateToGhostUserService).not_to receive(:execute)

        service.execute(user, hard_delete: true)

        expect(Issue.exists?(issue.id)).to be_falsy
      end
    end

    describe "user personal's repository removal" do
      before do
        Sidekiq::Testing.inline! { service.execute(user) }
      end

      context 'legacy storage' do
        let!(:project) { create(:project, :empty_repo, :legacy_storage, namespace: user.namespace) }

        it 'removes repository' do
          expect(gitlab_shell.exists?(project.repository_storage_path, "#{project.disk_path}.git")).to be_falsey
        end
      end

      context 'hashed storage' do
        let!(:project) { create(:project, :empty_repo, namespace: user.namespace) }

        it 'removes repository' do
          expect(gitlab_shell.exists?(project.repository_storage_path, "#{project.disk_path}.git")).to be_falsey
        end
      end
    end

    describe "calls the before/after callbacks" do
      it 'of project_members' do
        expect_any_instance_of(ProjectMember).to receive(:run_callbacks).with(:destroy).once

        service.execute(user)
      end

      it 'of group_members' do
        group_member = create(:group_member)
        group_member.group.group_members.create(user: user, access_level: 40)

        expect_any_instance_of(GroupMember).to receive(:run_callbacks).with(:destroy).once

        service.execute(user)
      end
    end
  end
end
