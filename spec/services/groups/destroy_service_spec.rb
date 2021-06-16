# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DestroyService do
  include DatabaseConnectionHelpers

  let!(:user)         { create(:user) }
  let!(:group)        { create(:group) }
  let!(:nested_group) { create(:group, parent: group) }
  let!(:project)      { create(:project, :repository, :legacy_storage, namespace: group) }
  let!(:notification_setting) { create(:notification_setting, source: group)}
  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:remove_path)  { group.path + "+#{group.id}+deleted" }

  before do
    group.add_user(user, Gitlab::Access::OWNER)
  end

  def destroy_group(group, user, async)
    if async
      Groups::DestroyService.new(group, user).async_execute
    else
      Groups::DestroyService.new(group, user).execute
    end
  end

  shared_examples 'group destruction' do |async|
    context 'database records', :sidekiq_might_not_need_inline do
      before do
        destroy_group(group, user, async)
      end

      it { expect(Group.unscoped.all).not_to include(group) }
      it { expect(Group.unscoped.all).not_to include(nested_group) }
      it { expect(Project.unscoped.all).not_to include(project) }
      it { expect(NotificationSetting.unscoped.all).not_to include(notification_setting) }
    end

    context 'mattermost team', :sidekiq_might_not_need_inline do
      let!(:chat_team) { create(:chat_team, namespace: group) }

      it 'destroys the team too' do
        expect_next_instance_of(::Mattermost::Team) do |instance|
          expect(instance).to receive(:destroy)
        end

        destroy_group(group, user, async)
      end
    end

    context 'file system', :sidekiq_might_not_need_inline do
      context 'Sidekiq inline' do
        before do
          # Run sidekiq immediately to check that renamed dir will be removed
          perform_enqueued_jobs { destroy_group(group, user, async) }
        end

        it 'verifies that paths have been deleted' do
          expect(TestEnv.storage_dir_exists?(project.repository_storage, group.path)).to be_falsey
          expect(TestEnv.storage_dir_exists?(project.repository_storage, remove_path)).to be_falsey
        end
      end
    end
  end

  describe 'asynchronous delete' do
    it_behaves_like 'group destruction', true

    context 'Sidekiq fake' do
      before do
        # Don't run Sidekiq to verify that group and projects are not actually destroyed
        Sidekiq::Testing.fake! { destroy_group(group, user, true) }
      end

      after do
        # Clean up stale directories
        TestEnv.rm_storage_dir(project.repository_storage, group.path)
        TestEnv.rm_storage_dir(project.repository_storage, remove_path)
      end

      it 'verifies original paths and projects still exist' do
        expect(TestEnv.storage_dir_exists?(project.repository_storage, group.path)).to be_truthy
        expect(TestEnv.storage_dir_exists?(project.repository_storage, remove_path)).to be_falsey
        expect(Project.unscoped.count).to eq(1)
        expect(Group.unscoped.count).to eq(2)
      end
    end
  end

  describe 'synchronous delete' do
    it_behaves_like 'group destruction', false
  end

  context 'projects in pending_delete' do
    before do
      project.pending_delete = true
      project.save!
    end

    it_behaves_like 'group destruction', false
  end

  context 'repository removal status is taken into account' do
    it 'raises exception' do
      expect_next_instance_of(::Projects::DestroyService) do |destroy_service|
        expect(destroy_service).to receive(:execute).and_return(false)
      end

      expect { destroy_group(group, user, false) }
        .to raise_error(Groups::DestroyService::DestroyError, "Project #{project.id} can't be deleted" )
    end
  end

  describe 'repository removal' do
    before do
      destroy_group(group, user, false)
    end

    context 'legacy storage' do
      let!(:project) { create(:project, :legacy_storage, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end
    end

    context 'hashed storage' do
      let!(:project) { create(:project, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end
    end
  end

  describe 'authorization updates', :sidekiq_inline do
    context 'for solo groups' do
      context 'group is deleted' do
        it 'updates project authorization' do
          expect { destroy_group(group, user, false) }.to(
            change { user.can?(:read_project, project) }.from(true).to(false))
        end

        it 'does not make use of a specific service to update project_authorizations records' do
          expect(UserProjectAccessChangedService)
            .not_to receive(:new).with(group.user_ids_for_project_authorizations)

          destroy_group(group, user, false)
        end
      end
    end

    context 'for shared groups within different hierarchies' do
      let(:shared_with_group) { group }
      let!(:shared_group) { create(:group, :private) }
      let!(:shared_group_child) { create(:group, :private, parent: shared_group) }
      let!(:shared_group_user) { create(:user) }

      let!(:project) { create(:project, group: shared_group) }
      let!(:project_child) { create(:project, group: shared_group_child) }

      before do
        shared_group.add_user(shared_group_user, Gitlab::Access::OWNER)

        create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_group)
        shared_with_group.refresh_members_authorized_projects
      end

      context 'the shared group is deleted' do
        it 'updates project authorization' do
          expect(shared_group_user.can?(:read_project, project)).to eq(true)
          expect(shared_group_user.can?(:read_project, project_child)).to eq(true)

          destroy_group(shared_group, shared_group_user, false)

          expect(shared_group_user.can?(:read_project, project)).to eq(false)
          expect(shared_group_user.can?(:read_project, project_child)).to eq(false)
        end

        it 'does not make use of specific service to update project_authorizations records' do
          expect(UserProjectAccessChangedService)
            .not_to receive(:new).with(shared_group.user_ids_for_project_authorizations).and_call_original

          destroy_group(shared_group, shared_group_user, false)
        end
      end

      context 'the shared_with group is deleted' do
        it 'updates project authorization' do
          expect(user.can?(:read_project, project)).to eq(true)
          expect(user.can?(:read_project, project_child)).to eq(true)

          destroy_group(shared_with_group, user, false)

          expect(user.can?(:read_project, project)).to eq(false)
          expect(user.can?(:read_project, project_child)).to eq(false)
        end

        it 'makes use of a specific service to update project_authorizations records' do
          expect(UserProjectAccessChangedService)
            .to receive(:new).with(shared_with_group.user_ids_for_project_authorizations).and_call_original

          destroy_group(shared_with_group, user, false)
        end
      end
    end

    context 'for shared groups in the same group hierarchy' do
      let(:shared_group) { group }
      let(:shared_with_group) { nested_group }
      let!(:shared_with_group_user) { create(:user) }

      before do
        shared_with_group.add_user(shared_with_group_user, Gitlab::Access::MAINTAINER)

        create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_group)
        shared_with_group.refresh_members_authorized_projects
      end

      context 'the shared group is deleted' do
        it 'updates project authorization' do
          expect { destroy_group(shared_group, user, false) }.to(
            change { shared_with_group_user.can?(:read_project, project) }.from(true).to(false))
        end

        it 'does not make use of a specific service to update project authorizations' do
          # Due to the recursive nature of `Groups::DestroyService`, `UserProjectAccessChangedService`
          # will still be executed for the nested group as they fall under the same hierarchy
          # and hence we need to account for this scenario.
          expect(UserProjectAccessChangedService)
            .to receive(:new).with(shared_with_group.users_ids_of_direct_members).and_call_original

          expect(UserProjectAccessChangedService)
            .not_to receive(:new).with(shared_group.users_ids_of_direct_members)

          destroy_group(shared_group, user, false)
        end
      end

      context 'the shared_with group is deleted' do
        it 'updates project authorization' do
          expect { destroy_group(shared_with_group, user, false) }.to(
            change { shared_with_group_user.can?(:read_project, project) }.from(true).to(false))
        end

        it 'makes use of a specific service to update project authorizations' do
          expect(UserProjectAccessChangedService)
            .to receive(:new).with(shared_with_group.users_ids_of_direct_members).and_call_original

          destroy_group(shared_with_group, user, false)
        end
      end
    end
  end
end
