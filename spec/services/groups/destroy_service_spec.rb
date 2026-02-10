# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DestroyService, feature_category: :groups_and_projects do
  include Namespaces::StatefulHelpers
  using RSpec::Parameterized::TableSyntax

  let!(:user)         { create(:user) }
  let!(:group)        { create(:group_with_deletion_schedule) }
  let!(:nested_group) { create(:group, parent: group) }
  let!(:project)      { create(:project, :repository, :legacy_storage, namespace: group) }
  let!(:notification_setting) { create(:notification_setting, source: group) }
  let(:remove_path)  { group.path + "+#{group.id}+deleted" }
  let(:removed_repo) { Gitlab::Git::Repository.new(project.repository_storage, remove_path, nil, nil) }

  before do
    group.add_member(user, Gitlab::Access::OWNER)
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

    context 'bot tokens', :sidekiq_inline do
      it 'initiates group bot removal', :aggregate_failures do
        bot = create(:user, :project_bot)
        group.add_developer(bot)
        create(:personal_access_token, user: bot)

        destroy_group(group, user, async)

        expect(
          Users::GhostUserMigration.where(user: bot, initiator_user: user)
        ).to be_exists
      end
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
          expect(removed_repo).not_to exist
        end
      end
    end

    context 'event store', :sidekiq_might_not_need_inline do
      it 'publishes a GroupDeletedEvent' do
        expect { destroy_group(group, user, async) }
          .to publish_event(Groups::GroupDeletedEvent)
            .with(
              group_id: group.id,
              root_namespace_id: group.root_ancestor.id
            )
          .and publish_event(Groups::GroupDeletedEvent)
            .with(
              group_id: nested_group.id,
              root_namespace_id: nested_group.root_ancestor.id,
              parent_namespace_id: group.id
            )
      end
    end

    it 'schedules removal of any associated direct transfer export uploads', :sidekiq_inline do
      allow(::Import::BulkImports::RemoveExportUploadsService).to receive(:new).and_call_original
      expect_next_instance_of(::Import::BulkImports::RemoveExportUploadsService) do |service|
        expect(service).to receive(:execute)
      end

      destroy_group(group, user, async)
    end
  end

  describe 'asynchronous delete' do
    it_behaves_like 'group destruction', true

    context 'when group state is deletion_scheduled' do
      before do
        set_state(group, :deletion_scheduled)
      end

      it 'transitions the group state to deletion_in_progress' do
        expect(group).to receive(:start_deletion!).with(transition_user: user).and_call_original

        expect { destroy_group(group, user, true) }.to change { group.state }
                                                         .from(Namespaces::Stateful::STATES[:deletion_scheduled])
                                                         .to(Namespaces::Stateful::STATES[:deletion_in_progress])
      end

      context 'when group is already in deletion_in_progress state' do
        before do
          set_state(group, :deletion_in_progress)
        end

        it 'does not call start_deletion!' do
          expect(group).not_to receive(:start_deletion!)

          destroy_group(group, user, true)
        end
      end
    end

    context 'Sidekiq fake' do
      before do
        # Don't run Sidekiq to verify that group and projects are not actually destroyed
        Sidekiq::Testing.fake! { destroy_group(group, user, true) }
        Sidekiq::Testing.fake! { destroy_group(nested_group, user, true) }
      end

      it 'verifies original paths and projects still exist' do
        expect(removed_repo).not_to exist
        expect(Project.unscoped.count).to eq(1)
        expect(Group.unscoped.count).to eq(2)
      end
    end
  end

  describe 'synchronous delete' do
    it_behaves_like 'group destruction', false

    context 'when destroying the group throws an error' do
      before do
        allow(group).to receive(:destroy).and_raise(StandardError)
      end

      context 'when group state is deletion_scheduled' do
        before do
          set_state(group, :deletion_scheduled)
        end

        it 'reschedules the deletion by transitioning state back' do
          expect(group).to receive(:reschedule_deletion!).with(transition_user: user).and_call_original

          expect { destroy_group(group, user, false) }.to raise_error(StandardError)
          expect(group.state).to eq(Namespaces::Stateful::STATES[:deletion_scheduled])
        end

        it 'logs the rescheduling error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              group_id: group.id,
              current_user: user.id,
              error_class: StandardError,
              message: "Rescheduling group deletion"
            )
          )

          expect { destroy_group(group, user, false) }.to raise_error(StandardError)
        end
      end
    end

    context 'when group state is deletion_scheduled' do
      before do
        set_state(group, :deletion_scheduled)
      end

      it 'transitions the group state to deletion_in_progress' do
        expect(group).to receive(:start_deletion!).with(transition_user: user).and_call_original

        expect { destroy_group(group, user, false) }.to change { group.state }
          .from(Namespaces::Stateful::STATES[:deletion_scheduled])
          .to(Namespaces::Stateful::STATES[:deletion_in_progress])
      end

      context 'when group is already in deletion_in_progress state' do
        before do
          set_state(group, :deletion_in_progress)
        end

        it 'does not call start_deletion!' do
          expect(group).not_to receive(:start_deletion!)

          destroy_group(group, user, false)
        end
      end

      context 'when deletion fails and reschedule_deletion is called' do
        where(:group_state, :nested_group_state) do
          :deletion_scheduled | :ancestor_inherited
          :deletion_scheduled | :archived
          :deletion_scheduled | :deletion_scheduled
        end

        with_them do
          before do
            set_state(group, group_state)
            set_state(nested_group, nested_group_state)
            allow_next_found_instance_of(Group) do |instance|
              allow(instance).to receive(:destroy).and_raise(StandardError)
            end
          end

          it 'restores each group to its original state before deletion started', :aggregate_failures do
            expect { destroy_group(group, user, false) }.to raise_error(StandardError)

            expect(group.reload.state).to eq(Namespaces::Stateful::STATES[group_state])
            expect(nested_group.reload.state).to eq(Namespaces::Stateful::STATES[nested_group_state])
          end
        end
      end
    end
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
        .to raise_error(described_class::DestroyError, "Project #{project.id} can't be deleted")
    end
  end

  context 'when group owner is blocked' do
    before do
      user.block!
    end

    it 'returns a more descriptive error message' do
      expect { destroy_group(group, user, false) }
        .to raise_error(described_class::DestroyError, "You can't delete this group because you're blocked.")
    end
  end

  context 'when user does not have authorization to delete the group' do
    let(:unauthorized_user) { create(:user) }

    it 'returns an unauthorized error response and does not mark deletion in progress' do
      expect(group).not_to be_member(unauthorized_user)

      result = destroy_group(group, unauthorized_user, false)

      expect(result).to eq(described_class::UnauthorizedError)
      expect(group.reload).not_to be_deletion_in_progress
      expect(group).not_to be_deletion_scheduled
    end

    it 'returns an unauthorized error response for async_execute' do
      expect(group).not_to be_member(unauthorized_user)

      result = destroy_group(group, unauthorized_user, true)

      expect(result).to eq(described_class::UnauthorizedError)
      expect(group.reload).not_to be_deletion_in_progress
    end
  end

  describe 'repository removal' do
    before do
      destroy_group(group, user, false)
    end

    context 'legacy storage' do
      let!(:project) { create(:project, :legacy_storage, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(project.repository.raw).not_to exist
      end
    end

    context 'hashed storage' do
      let!(:project) { create(:project, :empty_repo, namespace: group) }

      it 'removes repository' do
        expect(project.repository.raw).not_to exist
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
      let(:group1) { create(:group, :private) }
      let(:group2) { create(:group, :private) }

      let(:group1_user) { create(:user) }
      let(:group2_user) { create(:user) }

      before do
        group1.add_member(group1_user, Gitlab::Access::OWNER)
        group2.add_member(group2_user, Gitlab::Access::OWNER)
      end

      context 'when a project is shared with a group' do
        let!(:group1_project) { create(:project, :private, group: group1) }

        before do
          create(:project_group_link, project: group1_project, group: group2)
        end

        context 'and the shared group is deleted' do
          it 'updates project authorizations so group2 users no longer have access', :aggregate_failures do
            expect(group1_user.can?(:read_project, group1_project)).to eq(true)
            expect(group2_user.can?(:read_project, group1_project)).to eq(true)

            destroy_group(group2, group2_user, false)

            expect(group1_user.can?(:read_project, group1_project)).to eq(true)
            expect(group2_user.can?(:read_project, group1_project)).to eq(false)
          end

          it 'calls the service to update project authorizations only with necessary user ids' do
            expect(UserProjectAccessChangedService)
              .to receive(:new).with(array_including(group2_user.id)).and_call_original

            destroy_group(group2, group2_user, false)
          end
        end

        context 'and the group is shared with another group' do
          let(:group3) { create(:group, :private) }
          let(:group3_user) { create(:user) }

          before do
            group3.add_member(group3_user, Gitlab::Access::OWNER)

            create(:group_group_link, shared_group: group2, shared_with_group: group3)
            group3.refresh_members_authorized_projects
          end

          it 'updates project authorizations so group2 and group3 users no longer have access', :aggregate_failures do
            expect(group1_user.can?(:read_project, group1_project)).to eq(true)
            expect(group2_user.can?(:read_project, group1_project)).to eq(true)
            expect(group3_user.can?(:read_project, group1_project)).to eq(true)

            destroy_group(group2, group2_user, false)

            expect(group1_user.can?(:read_project, group1_project)).to eq(true)
            expect(group2_user.can?(:read_project, group1_project)).to eq(false)
            expect(group3_user.can?(:read_project, group1_project)).to eq(false)
          end

          it 'calls the service to update project authorizations only with necessary user ids' do
            expect(UserProjectAccessChangedService)
              .to receive(:new).with(array_including(group2_user.id, group3_user.id)).and_call_original

            destroy_group(group2, group2_user, false)
          end
        end
      end

      context 'when a group is shared with a group' do
        let!(:group2_project) { create(:project, :private, group: group2) }

        before do
          create(:group_group_link, shared_group: group2, shared_with_group: group1)
          group1.refresh_members_authorized_projects
        end

        context 'and the shared group is deleted' do
          it 'updates project authorizations since the project has been deleted with the group', :aggregate_failures do
            expect(group1_user.can?(:read_project, group2_project)).to eq(true)
            expect(group2_user.can?(:read_project, group2_project)).to eq(true)

            destroy_group(group2, group2_user, false)

            expect(group1_user.can?(:read_project, group2_project)).to eq(false)
            expect(group2_user.can?(:read_project, group2_project)).to eq(false)
          end

          it 'does not call the service to update project authorizations' do
            expect(UserProjectAccessChangedService).not_to receive(:new)

            destroy_group(group2, group2_user, false)
          end
        end

        context 'the shared_with group is deleted' do
          let!(:group2_subgroup) { create(:group, :private, parent: group2) }
          let!(:group2_subgroup_project) { create(:project, :private, group: group2_subgroup) }

          it 'updates project authorizations so users of both groups lose access', :aggregate_failures do
            expect(group1_user.can?(:read_project, group2_project)).to eq(true)
            expect(group2_user.can?(:read_project, group2_project)).to eq(true)
            expect(group1_user.can?(:read_project, group2_subgroup_project)).to eq(true)
            expect(group2_user.can?(:read_project, group2_subgroup_project)).to eq(true)

            destroy_group(group1, group1_user, false)

            expect(group1_user.can?(:read_project, group2_project)).to eq(false)
            expect(group2_user.can?(:read_project, group2_project)).to eq(true)
            expect(group1_user.can?(:read_project, group2_subgroup_project)).to eq(false)
            expect(group2_user.can?(:read_project, group2_subgroup_project)).to eq(true)
          end

          it 'calls the service to update project authorizations only with necessary user ids' do
            expect(UserProjectAccessChangedService)
              .to receive(:new).with([group1_user.id]).and_call_original

            destroy_group(group1, group1_user, false)
          end
        end
      end
    end

    context 'for shared groups in the same group hierarchy' do
      let(:shared_group) { group }
      let(:shared_with_group) { nested_group }
      let!(:shared_with_group_user) { create(:user) }

      before do
        shared_with_group.add_member(shared_with_group_user, Gitlab::Access::MAINTAINER)

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
