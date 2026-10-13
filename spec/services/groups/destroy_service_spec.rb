# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DestroyService, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }
  let!(:group)        { create(:group, :deletion_scheduled, owners: user) }
  let!(:nested_group) { create(:group, parent: group) }
  let!(:project)      { create(:project, :repository, :legacy_storage, namespace: group) }
  let(:remove_path)  { group.path + "+#{group.id}+deleted" }
  let(:removed_repo) { Gitlab::Git::Repository.new(project.repository_storage, remove_path, nil, nil) }

  def destroy_group(group, user, async)
    if async
      Groups::DestroyService.new(group, user).async_execute
    else
      Groups::DestroyService.new(group, user).execute
    end
  end

  shared_examples 'group destruction' do |async|
    context 'database records', :sidekiq_might_not_need_inline do
      let!(:notification_setting) { create(:notification_setting, source: group) }

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

      context 'when Mattermost team removal raises Gitlab::HTTP::BlockedUrlError' do
        before do
          allow_next_instance_of(::Mattermost::Team) do |instance|
            allow(instance).to receive(:destroy)
              .and_raise(Gitlab::HTTP_V2::BlockedUrlError, 'URL is blocked: Only allowed schemes are https')
          end
        end

        it 'still destroys the group' do
          destroy_group(group, user, async)

          expect(Group.unscoped.all).not_to include(group)
        end

        it 'logs a warning' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              message: "Mattermost team deletion failed, proceeding with group deletion",
              Labkit::Fields::ERROR_TYPE => 'Gitlab::HTTP_V2::BlockedUrlError'
            )
          )

          destroy_group(group, user, async)
        end
      end

      context 'when Mattermost team removal raises Mattermost::ConnectionError' do
        before do
          stub_const('Mattermost::ConnectionError', Class.new(::Mattermost::Error))
          allow_next_instance_of(::Mattermost::Team) do |instance|
            allow(instance).to receive(:destroy)
              .and_raise(::Mattermost::ConnectionError, 'connection refused')
          end
        end

        it 'still destroys the group' do
          destroy_group(group, user, async)

          expect(Group.unscoped.all).not_to include(group)
        end
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
        group.update!(state: :deletion_scheduled)
      end

      it 'transitions the group state to deletion_in_progress' do
        expect(group).to receive(:start_deletion!).with(transition_user: user).and_call_original

        expect { destroy_group(group, user, true) }.to change { group.state }
                                                         .from('deletion_scheduled')
                                                         .to('deletion_in_progress')
      end

      context 'when group is already in deletion_in_progress state' do
        before do
          group.update!(state: :deletion_in_progress)
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
          group.update!(state: :deletion_scheduled)
        end

        it 'reschedules the deletion by transitioning state back' do
          expect(group).to receive(:reschedule_deletion!)
            .with(transition_user: user, deletion_error: anything)
            .and_call_original

          expect { destroy_group(group, user, false) }.to raise_error(StandardError)
          expect(group.state).to eq('deletion_scheduled')
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
        group.update!(state: :deletion_scheduled)
      end

      it 'transitions the group state to deletion_in_progress' do
        expect(group).to receive(:start_deletion!).with(transition_user: user).and_call_original

        expect { destroy_group(group, user, false) }.to change { group.state }
          .from('deletion_scheduled')
          .to('deletion_in_progress')
      end

      context 'when group is already in deletion_in_progress state' do
        before do
          group.update!(state: :deletion_in_progress)
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
            group.update!(state: group_state)
            nested_group.update!(state: nested_group_state)
            allow_next_found_instance_of(Group) do |instance|
              allow(instance).to receive(:destroy).and_raise(StandardError)
            end
          end

          it 'restores each group to its original state before deletion started', :aggregate_failures do
            expect { destroy_group(group, user, false) }.to raise_error(StandardError)

            expect(group.reload.state).to eq(group_state.to_s)
            expect(nested_group.reload.state).to eq(nested_group_state.to_s)
          end
        end
      end

      context 'when a descendant is in a transient transfer state during deletion' do
        # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/608541
        where(:nested_group_state) do
          [[:transfer_in_progress], [:transfer_scheduled]]
        end

        with_them do
          before do
            nested_group.update!(state: nested_group_state)
          end

          it 'destroys the group and its descendant', :aggregate_failures do
            destroy_group(group, user, false)

            expect(Group.unscoped.all).not_to include(group)
            expect(Group.unscoped.all).not_to include(nested_group)
          end
        end
      end

      context 'when reschedule_deletion! itself raises during the rescue block' do
        # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/608541
        #
        # If reschedule_deletion! raises (e.g. due to an unexpected state), the
        # original exception must still be re-raised so callers and logs see the
        # real root cause rather than a secondary StateMachines::InvalidTransition.
        before do
          group.update!(state: :deletion_scheduled)
          allow(group).to receive(:destroy).and_raise(StandardError, 'original error')
          allow(group).to receive(:reschedule_deletion!).and_raise(RuntimeError, 'reschedule failed')
        end

        it 're-raises the original exception, not the reschedule error' do
          expect { destroy_group(group, user, false) }.to raise_error(StandardError, 'original error')
        end

        it 'logs the reschedule failure alongside the original error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: "Rescheduling group deletion failed",
              reschedule_error_class: RuntimeError,
              reschedule_error_message: 'reschedule failed'
            )
          )

          expect { destroy_group(group, user, false) }.to raise_error(StandardError, 'original error')
        end

        it 'tracks the reschedule exception on Sentry' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            an_instance_of(RuntimeError).and(having_attributes(message: 'reschedule failed')),
            group_id: group.id
          )

          expect { destroy_group(group, user, false) }.to raise_error(StandardError, 'original error')
        end
      end

      context 'when deletion fails without a current_user' do
        before do
          allow(group).to receive(:start_deletion!).and_raise(StandardError, 'original error')
        end

        it 'logs the failure with a nil user and re-raises' do
          allow(Gitlab::AppLogger).to receive(:error)
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(group_id: group.id, current_user: nil, error_message: 'original error')
          )

          expect { described_class.new(group, nil).unsafe_execute }.to raise_error(StandardError, 'original error')
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

  context 'when a before_destroy callback aborts the destroy' do
    before do
      allow(group).to receive(:destroy) do
        group.errors.add(:base, 'cannot be deleted right now')
        false
      end
    end

    it 'raises DestroyError instead of reporting success', :aggregate_failures do
      expect { destroy_group(group, user, false) }
        .to raise_error(described_class::DestroyError, 'cannot be deleted right now')

      expect(Group.exists?(group.id)).to be(true)
    end
  end

  context 'when a before_destroy callback aborts the destroy without adding an error' do
    before do
      allow(group).to receive(:destroy).and_return(false)
    end

    it 'falls back to a message naming the group instead of raising with a blank message' do
      expect { destroy_group(group, user, false) }
        .to raise_error(described_class::DestroyError, "Group #{group.id} can't be deleted")
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
    let_it_be(:unauthorized_user) { create(:user) }

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
        shared_examples 'updates project authorization' do
          it 'updates project authorization' do
            expect { destroy_group(group, user, false) }.to(
              change { user.can?(:read_project, project) }.from(true).to(false))
          end
        end

        it_behaves_like 'updates project authorization'

        it 'does not make use of a specific service to update project_authorizations records' do
          expect(AuthorizedProjectUpdate::ProjectAccessChangedService).not_to receive(:new)

          destroy_group(group, user, false)
        end
      end
    end

    context 'for shared groups across different hierarchies' do
      let_it_be(:group1_user) { create(:user) }
      let_it_be(:group2_user) { create(:user) }

      let(:group1) { create(:group, :private, owners: group1_user) }
      let(:group2) { create(:group, :private, owners: group2_user) }

      context 'when a project is shared' do
        # group1
        #  `- group1_project
        # group2
        #  `- group1_project (via project_group_link)
        let!(:group1_project) { create(:project, :private, group: group1) }

        before do
          create(:project_group_link, project: group1_project, group: group2)
        end

        context 'and the invited group is destroyed' do
          shared_examples 'updates project authorizations so users of the destroyed group no longer have access' do
            it 'updates project authorizations so users of the destroyed group no longer have access',
              :aggregate_failures do
              expect(group1_user.can?(:read_project, group1_project)).to be(true)
              expect(group2_user.can?(:read_project, group1_project)).to be(true)

              destroy_group(group2, group2_user, false)

              expect(group1_user.can?(:read_project, group1_project)).to be(true)
              expect(group2_user.can?(:read_project, group1_project)).to be(false)
            end
          end

          context 'when user has direct access to the project' do
            before do
              group1_project.add_guest(group2_user)
            end

            it 'retains the user\'s direct access to the project' do
              expect(group2_user.can?(:read_project, group1_project)).to be(true)
              expect(group1_project.team.human_max_access(group2_user.id)).to eq('Developer')

              destroy_group(group2, group2_user, false)

              expect(group2_user.can?(:read_project, group1_project)).to be(true)
              expect(group1_project.team.human_max_access(group2_user.id)).to eq('Guest')
            end
          end

          it_behaves_like 'updates project authorizations so users of the destroyed group no longer have access'

          it 'calls the service to update project authorizations only with necessary project ids' do
            expect(AuthorizedProjectUpdate::ProjectAccessChangedService)
              .to receive(:new).with(array_including(group1_project.id)).and_call_original

            destroy_group(group2, group2_user, false)
          end

          it 'logs the project-based project_authorizations refresh' do
            allow(Gitlab::AppLogger).to receive(:info).and_call_original
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: "Refreshing project_authorizations for projects previously shared with destroyed group",
                group_id: group2.id,
                user_ids_count: 0,
                project_ids_count: a_value > 0
              )
            ).and_call_original

            destroy_group(group2, group2_user, false)
          end
        end

        context 'and the group is shared with another group' do
          # group1
          #  `- group1_project
          # group2
          #  `- group1_project (via project_group_link)
          # group3
          #  `- group1_project (via project_group_link between group1 and group2)
          #
          # group3 is invited to group2, and thus has access to group1_project
          # via group2's share link. When group2 is deleted, we need to make
          # sure that group3's access to group1_project is also removed.
          let_it_be(:group3_user) { create(:user) }
          let_it_be(:group3) { create(:group, :private, owners: group3_user) }

          before do
            create(:group_group_link, shared_group: group2, shared_with_group: group3)
            group3.refresh_members_authorized_projects
          end

          shared_examples 'updates project authorizations so group2 and group3 users no longer have access' do
            it 'updates project authorizations so group2 and group3 users no longer have access', :aggregate_failures do
              expect(group1_user.can?(:read_project, group1_project)).to be(true)
              expect(group2_user.can?(:read_project, group1_project)).to be(true)
              expect(group3_user.can?(:read_project, group1_project)).to be(true)

              destroy_group(group2, group2_user, false)

              expect(group1_user.can?(:read_project, group1_project)).to be(true)
              expect(group2_user.can?(:read_project, group1_project)).to be(false)
              expect(group3_user.can?(:read_project, group1_project)).to be(false)
            end
          end

          it_behaves_like 'updates project authorizations so group2 and group3 users no longer have access'

          it 'calls the service to update project authorizations only with necessary project ids' do
            expect(AuthorizedProjectUpdate::ProjectAccessChangedService)
              .to receive(:new).with(array_including(group1_project.id)).and_call_original

            destroy_group(group2, group2_user, false)
          end
        end
      end

      context 'when a group is shared with a group' do
        # group2 (shared group)
        #  `- group2_project
        # group1 (invited group / shared_with group)
        #  `- group2_project (via group_group_link)
        let!(:group2_project) { create(:project, :private, group: group2) }

        before do
          create(:group_group_link, shared_group: group2, shared_with_group: group1)
          group1.refresh_members_authorized_projects
        end

        context 'and the shared group is deleted' do
          shared_examples 'updates project authorizations since the project has been deleted with the group' do
            it 'updates project authorizations since the project has been deleted with the group',
              :aggregate_failures do
              expect(group1_user.can?(:read_project, group2_project)).to be(true)
              expect(group2_user.can?(:read_project, group2_project)).to be(true)

              destroy_group(group2, group2_user, false)

              expect(group1_user.can?(:read_project, group2_project)).to be(false)
              expect(group2_user.can?(:read_project, group2_project)).to be(false)
            end
          end

          it_behaves_like 'updates project authorizations since the project has been deleted with the group'

          it 'does not call the service to update project authorizations' do
            expect(AuthorizedProjectUpdate::ProjectAccessChangedService).not_to receive(:new)

            destroy_group(group2, group2_user, false)
          end
        end

        # group2 (shared group)
        #  `- group2_project
        #  `- group2_subgroup
        #       `- group2_subgroup_project
        # group1 (invited group / shared_with group)
        #  `- group2_project (via group_group_link)
        #  `- group2_subgroup_project (via group_group_link)
        context 'the shared_with group is deleted' do
          let!(:group2_subgroup) { create(:group, :private, parent: group2) }
          let!(:group2_subgroup_project) { create(:project, :private, group: group2_subgroup) }

          shared_examples 'updates project authorizations so users of both groups lose access' do
            it 'updates project authorizations so users of both groups lose access', :aggregate_failures do
              expect(group1_user.can?(:read_project, group2_project)).to be(true)
              expect(group2_user.can?(:read_project, group2_project)).to be(true)
              expect(group1_user.can?(:read_project, group2_subgroup_project)).to be(true)
              expect(group2_user.can?(:read_project, group2_subgroup_project)).to be(true)

              destroy_group(group1, group1_user, false)

              expect(group1_user.can?(:read_project, group2_project)).to be(false)
              expect(group2_user.can?(:read_project, group2_project)).to be(true)
              expect(group1_user.can?(:read_project, group2_subgroup_project)).to be(false)
              expect(group2_user.can?(:read_project, group2_subgroup_project)).to be(true)
            end
          end

          context 'when user has direct access to the shared group' do
            before do
              group2.add_guest(group1_user)
            end

            it 'retains the user\'s direct access to the shared group\'s projects' do
              expect(group1_user.can?(:read_project, group2_project)).to be(true)
              expect(group1_user.can?(:read_project, group2_subgroup_project)).to be(true)
              expect(group2_project.team.human_max_access(group1_user.id)).to eq('Developer')
              expect(group2_subgroup_project.team.human_max_access(group1_user.id)).to eq('Developer')

              destroy_group(group1, group1_user, false)

              expect(group1_user.can?(:read_project, group2_project)).to be(true)
              expect(group1_user.can?(:read_project, group2_subgroup_project)).to be(true)
              expect(group2_project.team.human_max_access(group1_user.id)).to eq('Guest')
              expect(group2_subgroup_project.team.human_max_access(group1_user.id)).to eq('Guest')
            end
          end

          it_behaves_like 'updates project authorizations so users of both groups lose access'

          it 'calls the service to update project authorizations only with necessary project ids' do
            expect(AuthorizedProjectUpdate::ProjectAccessChangedService)
              .to receive(:new).with(array_including(group2_project.id, group2_subgroup_project.id)).and_call_original

            destroy_group(group1, group1_user, false)
          end

          it 'collects descendant project ids via the GIN-indexed containment path' do
            service = described_class.new(group1, group1_user)
            project_ids = nil

            recorder = ActiveRecord::QueryRecorder.new do
              project_ids = service.send(:obtain_project_ids_for_authorization_refresh)
            end

            expect(project_ids).to include(group2_project.id, group2_subgroup_project.id)
            expect(recorder.log).to include(a_string_matching(/traversal_ids @>/))
            expect(recorder.log).not_to include(a_string_matching(/next_traversal_ids_sibling/))
          end
        end
      end
    end

    # shared_group
    #  `- project
    #  `- shared_with_group
    #       `- project (via group_group_link)
    context 'for shared groups in the same group hierarchy' do
      let_it_be(:shared_with_group_user) { create(:user) }
      let(:shared_group) { group }
      let(:shared_with_group) { nested_group }

      before do
        shared_with_group.add_member(shared_with_group_user, Gitlab::Access::MAINTAINER)

        create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_group)
        shared_with_group.refresh_members_authorized_projects
      end

      context 'the shared group is deleted' do
        shared_examples 'updates project authorization' do
          it 'updates project authorization' do
            expect { destroy_group(shared_group, user, false) }.to(
              change { shared_with_group_user.can?(:read_project, project) }.from(true).to(false))
          end
        end

        it_behaves_like 'updates project authorization'

        it 'does not make use of a specific service to update project authorizations' do
          # The shared_group's own projects are deleted before its children are recursively
          # destroyed. By the time shared_with_group (nested_group) processes its share links,
          # shared_group has no remaining projects, so the affected project IDs set is empty
          # and no refresh service is called.
          expect(AuthorizedProjectUpdate::ProjectAccessChangedService).not_to receive(:new)

          destroy_group(shared_group, user, false)
        end
      end

      context 'the shared_with group is deleted' do
        shared_examples 'updates project authorization' do
          it 'updates project authorization', :aggregate_failures do
            expect(user.can?(:read_project, project)).to be(true)
            expect(shared_with_group_user.can?(:read_project, project)).to be(true)

            destroy_group(shared_with_group, user, false)

            expect(user.can?(:read_project, project)).to be(true)
            expect(shared_with_group_user.can?(:read_project, project)).to be(false)
          end
        end

        it_behaves_like 'updates project authorization'

        it 'makes use of a specific service to update project authorizations' do
          expect(AuthorizedProjectUpdate::ProjectAccessChangedService)
            .to receive(:new).with(array_including(project.id)).and_call_original

          destroy_group(shared_with_group, user, false)
        end
      end
    end
  end

  describe '#track_destroy_failure' do
    before do
      allow(group).to receive(:destroy).and_raise(StandardError, 'something broke')
      allow(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original
    end

    it 'increments deletion_attempt_count on each failed destroy' do
      expect { destroy_group(group, user, false) }.to raise_error(StandardError)

      expect(group.reload.deletion_attempt_count).to eq(1)
    end

    it 'records deletion_last_failed_at' do
      freeze_time do
        expect { destroy_group(group, user, false) }.to raise_error(StandardError)

        expect(group.reload.deletion_last_failed_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when deletion_attempt_count is below MAX_DESTROY_ATTEMPTS' do
      before do
        below_threshold = described_class::MAX_DESTROY_ATTEMPTS - 2
        group.namespace_details.update!(
          state_metadata: group.namespace_details.state_metadata.merge('deletion_attempt_count' => below_threshold)
        )
      end

      it 'reports the per-failure error to Sentry but does not escalate with DeletionStuckError' do
        expect { destroy_group(group, user, false) }.to raise_error(StandardError)

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).once.with(
          an_object_having_attributes(message: a_string_including('something broke')),
          hash_including(group_id: group.id, deletion_attempt_count: described_class::MAX_DESTROY_ATTEMPTS - 1)
        )
        expect(Gitlab::ErrorTracking).not_to have_received(:track_exception).with(
          an_instance_of(described_class::DeletionStuckError), anything
        )
      end
    end

    context 'when deletion_attempt_count reaches MAX_DESTROY_ATTEMPTS' do
      before do
        one_below = described_class::MAX_DESTROY_ATTEMPTS - 1
        group.namespace_details.update!(
          state_metadata: group.namespace_details.state_metadata.merge('deletion_attempt_count' => one_below)
        )
      end

      context 'when the previous failure is recent (inside STUCK_FAILURE_WINDOW)' do
        before do
          group.namespace_details.update!(
            state_metadata: group.namespace_details.state_metadata.merge(
              'deletion_last_failed_at' => 1.hour.ago.iso8601
            )
          )
        end

        it 'reports the per-failure error but does not escalate with DeletionStuckError' do
          expect { destroy_group(group, user, false) }.to raise_error(StandardError)

          expect(Gitlab::ErrorTracking).to have_received(:track_exception).once.with(
            an_object_having_attributes(message: a_string_including('something broke')),
            hash_including(group_id: group.id, deletion_attempt_count: described_class::MAX_DESTROY_ATTEMPTS)
          )
          expect(Gitlab::ErrorTracking).not_to have_received(:track_exception).with(
            an_instance_of(described_class::DeletionStuckError), anything
          )
        end
      end

      context 'when the previous failure is older than STUCK_FAILURE_WINDOW' do
        before do
          group.namespace_details.update!(
            state_metadata: group.namespace_details.state_metadata.merge(
              'deletion_last_failed_at' => 13.hours.ago.iso8601
            )
          )
        end

        it 'reports the per-failure error and escalates with DeletionStuckError' do
          expect { destroy_group(group, user, false) }.to raise_error(StandardError)

          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
            an_instance_of(StandardError).and(having_attributes(message: 'something broke')),
            hash_including(group_id: group.id, deletion_attempt_count: described_class::MAX_DESTROY_ATTEMPTS)
          )
          expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
            an_instance_of(described_class::DeletionStuckError).and(having_attributes(
              message: 'Group stuck in deletion: something broke'
            )),
            hash_including(
              group_id: group.id,
              deletion_attempt_count: described_class::MAX_DESTROY_ATTEMPTS
            )
          )
        end
      end
    end
  end
end
