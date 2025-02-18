# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::DestroyService, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user) }

  let(:member_user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:group_project) { create(:project, :public, group: group) }
  let(:opts) { {} }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(current_user).execute(member) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(current_user).execute(member) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service destroying a member' do
    before do
      type = member.is_a?(GroupMember) ? 'Group' : 'Project'
      expect(TodosDestroyer::EntityLeaveWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, member.user_id, member.source_id, type)
      expect(MembersDestroyer::UnassignIssuablesWorker).to receive(:perform_async).with(member.user_id, member.source_id, type, current_user.id) if opts[:unassign_issuables]
    end

    it 'destroys the member' do
      expect { described_class.new(current_user).execute(member, **opts) }.to change { member.source.members_and_requesters.count }.by(-1)
    end

    it 'destroys member notification_settings' do
      if member_user.notification_settings.any?
        expect { described_class.new(current_user).execute(member, **opts) }
          .to change { member_user.notification_settings.count }.by(-1)
      else
        expect { described_class.new(current_user).execute(member, **opts) }
          .not_to change { member_user.notification_settings.count }
      end
    end

    it 'resolves the access request todos for the owner' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:resolve_access_request_todos).with(member)
      end

      described_class.new(current_user).execute(member, **opts)
    end

    it 'triggers members destroyed event' do
      expect(Gitlab::EventStore)
        .to receive(:publish)
        .with(an_instance_of(Members::DestroyedEvent))
        .and_call_original

      described_class.new(current_user).execute(member, **opts)
    end

    it 'does not remove user from organization' do
      expect { described_class.new(current_user).execute(member, **opts) }
        .not_to change { member.source.organization.organization_users.count }
    end
  end

  shared_examples 'a service destroying a member with access' do
    it_behaves_like 'a service destroying a member'

    it 'invalidates cached counts for assigned issues and merge requests', :aggregate_failures, :sidekiq_might_not_need_inline do
      create(:issue, project: group_project, assignees: [member_user])
      create(:merge_request, source_project: group_project, assignees: [member_user])
      create(:todo, :pending, project: group_project, user: member_user)
      create(:todo, :done, project: group_project, user: member_user)

      expect(member_user.assigned_open_merge_requests_count).to be(1)
      expect(member_user.assigned_open_issues_count).to be(1)
      expect(member_user.todos_pending_count).to be(1)
      expect(member_user.todos_done_count).to be(1)

      service = described_class.new(current_user)

      if opts[:unassign_issuables]
        expect(service).to receive(:enqueue_unassign_issuables).with(member)
      end

      service.execute(member, **opts)

      expect(member_user.assigned_open_merge_requests_count).to be(0)
      expect(member_user.assigned_open_issues_count).to be(0)
      expect(member_user.todos_pending_count).to be(0)
      expect(member_user.todos_done_count).to be(0)

      unless opts[:unassign_issuables]
        expect(member_user.assigned_merge_requests.opened.count).to be(1)
        expect(member_user.assigned_issues.opened.count).to be(1)
      end
    end
  end

  shared_examples 'a service destroying an access request of another user' do
    it_behaves_like 'a service destroying a member'

    it 'calls the access denied mailer' do
      allow(Members::AccessDeniedMailer).to receive(:email).with(member: member).and_call_original

      expect do
        described_class.new(current_user).execute(member, **opts)
      end.to have_enqueued_mail(Members::AccessDeniedMailer, :email)
    end
  end

  shared_examples 'a service destroying an access request of self' do
    it_behaves_like 'a service destroying a member'

    context 'when current user is the member' do
      it 'does not call the access denied mailer' do
        expect do
          described_class.new(current_user).execute(member, **opts)
        end.not_to have_enqueued_mail(Members::AccessDeniedMailer, :email)
      end
    end
  end

  context 'With ExclusiveLeaseHelpers' do
    include ExclusiveLeaseHelpers

    let(:lock_key) do
      "delete_members:#{member_to_delete.source.class}:#{member_to_delete.source.id}"
    end

    let(:timeout) { 1.minute }
    let(:service_object) { described_class.new(current_user) }

    subject(:destroy_member) { service_object.execute(member_to_delete, **opts) }

    context 'for group members' do
      before do
        group.add_owner(current_user)
      end

      context 'deleting group owners' do
        let!(:member_to_delete) { group.add_owner(member_user) }

        context 'locking to avoid race conditions' do
          it 'tries to perform the delete within a lock' do
            expect_to_obtain_exclusive_lease(lock_key, timeout: timeout)

            destroy_member
          end

          context 'based on status of the lock' do
            context 'when lock is obtained' do
              it 'destroys the membership' do
                expect_to_obtain_exclusive_lease(lock_key, timeout: timeout)

                expect { destroy_member }.to change { group.members.count }.by(-1)
              end
            end

            context 'when the lock cannot be obtained' do
              before do
                stub_exclusive_lease_taken(lock_key, timeout: timeout)
              end

              it 'raises error' do
                expect { destroy_member }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
              end
            end
          end
        end
      end

      context 'deleting group members that are not owners' do
        let!(:member_to_delete) { group.add_developer(member_user) }

        it 'does not try to perform the deletion of the member within a lock' do
          # We need to account for other places involved in the Member deletion process that
          # uses ExclusiveLease.

          # `UpdateHighestRole` concern uses locks to peform work
          # whenever a Member is committed, so that needs to be accounted for.
          lock_key_for_update_highest_role = "update_highest_role:#{member_to_delete.user_id}"

          expect(Gitlab::ExclusiveLease)
            .to receive(:new).with(lock_key_for_update_highest_role, timeout: 10.minutes.to_i).and_call_original

          # We do not use any locks for the member deletion process, from within this service.
          expect(Gitlab::ExclusiveLease)
            .not_to receive(:new).with(lock_key, timeout: timeout)

          destroy_member
        end

        it 'destroys the membership' do
          expect { destroy_member }.to change { group.members.count }.by(-1)
        end
      end
    end

    context 'for project members' do
      shared_examples_for 'deletes the project member without using a lock' do
        let(:lock_key_for_update_highest_role) { "update_highest_role:#{member_to_delete.user_id}" }
        let(:lock_key_for_authorizations_refresh) { "authorized_project_update/project_recalculate_worker/projects/#{member_to_delete.project.id}" }

        it 'does not try to perform the deletion of a project member within a lock', :aggregate_failures do
          # We need to account for other places involved in the Member deletion process that
          # uses ExclusiveLease.

          # 1. `UpdateHighestRole` concern uses locks to peform work
          # whenever a Member is committed, so that needs to be accounted for.
          expect(Gitlab::ExclusiveLease)
            .to receive(:new).with(lock_key_for_update_highest_role, timeout: 10.minutes.to_i).and_call_original

          # 2. `AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker` does not use a lock to refresh
          # a user's authorizations has to be refreshed
          expect(Gitlab::ExclusiveLease)
            .not_to receive(:new).with(lock_key_for_authorizations_refresh, timeout: 10.seconds)

          # We do not use any locks for the member deletion process, from within this service.
          expect(Gitlab::ExclusiveLease)
            .not_to receive(:new).with(lock_key, timeout: timeout)

          destroy_member
        end

        it 'destroys the membership' do
          expect { destroy_member }.to change { entity.members.count }.by(-1)
        end
      end

      before do
        group_project.add_owner(current_user)
      end

      context 'deleting project owners' do
        context 'deleting project owners' do
          let!(:member_to_delete) { entity.add_owner(member_user) }

          it_behaves_like 'deletes the project member without using a lock' do
            let(:entity) { group_project }
          end
        end
      end

      context 'deleting project members that are not owners' do
        let!(:member_to_delete) { group_project.add_developer(member_user) }

        it_behaves_like 'deletes the project member without using a lock' do
          let(:entity) { group_project }
        end
      end
    end
  end

  context 'with a member with access' do
    before do
      group_project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
    end

    context 'when current user cannot destroy the given member' do
      context 'with a project member' do
        let(:member) { group_project.members.find_by(user_id: member_user.id) }

        context 'when current user does not have any membership management permissions' do
          before do
            group_project.add_developer(member_user)
          end

          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'

          context 'when skipping authorisation' do
            it_behaves_like 'a service destroying a member with access' do
              let(:opts) { { skip_authorization: true, unassign_issuables: true } }
            end
          end
        end

        context 'when a project maintainer tries to destroy a project owner' do
          before do
            group_project.add_owner(member_user)
          end

          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'

          context 'when skipping authorisation' do
            it_behaves_like 'a service destroying a member with access' do
              let(:opts) { { skip_authorization: true, unassign_issuables: true } }
            end
          end
        end
      end
    end

    context 'with a group member' do
      let(:member) { group.members.find_by(user_id: member_user.id) }

      before do
        group.add_developer(member_user)
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'

      context 'when skipping authorisation' do
        it_behaves_like 'a service destroying a member with access' do
          let(:opts) { { skip_authorization: true, unassign_issuables: true } }
        end
      end
    end

    context 'when current user can destroy the given member' do
      before do
        group_project.add_maintainer(current_user)
        group.add_owner(current_user)
      end

      context 'with a project member' do
        let(:member) { group_project.members.find_by(user_id: member_user.id) }

        before do
          group_project.add_developer(member_user)
        end

        it_behaves_like 'a service destroying a member with access'

        context 'unassign issuables' do
          it_behaves_like 'a service destroying a member with access' do
            let(:opts) { { unassign_issuables: true } }
          end
        end
      end

      context 'with a project bot member' do
        let(:member) { group_project.members.find_by(user_id: member_user.id) }
        let(:member_user) { create(:user, :project_bot) }

        before do
          group_project.add_maintainer(member_user)
        end

        context 'when the destroy_bot flag is true' do
          it_behaves_like 'a service destroying a member with access' do
            let(:opts) { { destroy_bot: true } }
          end
        end

        context 'when the destroy_bot flag is not specified' do
          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
        end
      end

      context 'with a group member' do
        let(:member) { group.members.find_by(user_id: member_user.id) }

        before do
          group.add_developer(member_user)
        end

        it_behaves_like 'a service destroying a member with access'

        context 'unassign issuables' do
          it_behaves_like 'a service destroying a member with access' do
            let(:opts) { { unassign_issuables: true } }
          end
        end
      end
    end
  end

  context 'with an access requester' do
    before do
      group_project.update!(request_access_enabled: true)
      group.update!(request_access_enabled: true)
      group_project.request_access(member_user)
      group.request_access(member_user)
    end

    context 'when current user cannot destroy the given access requester' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true, skip_subresources: true } }
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true, skip_subresources: true } }
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end
    end

    context 'when current user can destroy the given access requester' do
      let(:opts) { { skip_subresources: true } }

      before do
        group_project.add_maintainer(current_user)
        group.add_owner(current_user)
      end

      it_behaves_like 'a service destroying an access request of another user' do
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying an access request of another user' do
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end
    end

    context 'on withdrawing their own access request' do
      let(:opts) { { skip_subresources: true } }
      let(:current_user) { member_user }

      it_behaves_like 'a service destroying an access request of self' do
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying an access request of self' do
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end
    end
  end

  context 'with an invited user' do
    let(:project_invited_member) { create(:project_member, :invited, project: group_project) }
    let(:group_invited_member) { create(:group_member, :invited, group: group) }

    context 'when current user cannot destroy the given invited user' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { project_invited_member }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { project_invited_member }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group_invited_member }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { group_invited_member }
      end
    end

    context 'when current user can destroy the given invited user' do
      before do
        group_project.add_maintainer(current_user)
        group.add_owner(current_user)
      end

      # Regression spec for issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/32504
      it_behaves_like 'a service destroying a member' do
        let(:member) { project_invited_member }
      end

      it_behaves_like 'a service destroying a member' do
        let(:member) { group_invited_member }
      end
    end
  end

  context 'subresources' do
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be_with_reload(:member_user) { create(:user) }

    let_it_be_with_reload(:group) { create(:group, :public) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be(:private_subgroup) { create(:group, :private, parent: group, name: 'private_subgroup') }
    let_it_be(:private_subgroup_with_direct_membership) { create(:group, :private, parent: group) }
    let_it_be_with_reload(:subsubgroup) { create(:group, parent: subgroup) }

    let_it_be_with_reload(:group_project) { create(:project, :public, group: group) }
    let_it_be_with_reload(:control_project) { create(:project, :private, group: subsubgroup) }
    let_it_be_with_reload(:subsubproject) { create(:project, :public, group: subsubgroup) }

    let_it_be(:private_subgroup_project) do
      create(:project, :private, group: private_subgroup, name: 'private_subgroup_project')
    end

    let_it_be(:private_subgroup_with_direct_membership_project) do
      create(:project, :private, group: private_subgroup_with_direct_membership, name: 'private_subgroup_project')
    end

    context 'with memberships' do
      before do
        subgroup.add_developer(member_user)
        subsubgroup.add_developer(member_user)
        subsubproject.add_developer(member_user)
        group_project.add_developer(member_user)
        control_project.add_maintainer(user)
        private_subgroup_with_direct_membership.add_developer(member_user)
        group.add_owner(user)

        @group_member = create(:group_member, :developer, group: group, user: member_user)
      end

      let_it_be(:todo_in_public_group_project) do
        create(:todo, :pending,
          project: group_project,
          user: member_user,
          target: create(:issue, project: group_project)
        )
      end

      let_it_be(:mr_in_public_group_project) do
        create(:merge_request, source_project: group_project, assignees: [member_user])
      end

      let_it_be(:todo_in_private_subgroup_project) do
        create(:todo, :pending,
          project: private_subgroup_project,
          user: member_user,
          target: create(:issue, project: private_subgroup_project)
        )
      end

      let_it_be(:mr_in_private_subgroup_project) do
        create(:merge_request, source_project: private_subgroup_project, assignees: [member_user])
      end

      let_it_be(:todo_in_public_subsubgroup_project) do
        create(:todo, :pending,
          project: subsubproject,
          user: member_user,
          target: create(:issue, project: subsubproject)
        )
      end

      let_it_be(:mr_in_public_subsubgroup_project) do
        create(:merge_request, source_project: subsubproject, assignees: [member_user])
      end

      let_it_be(:todo_in_private_subgroup_with_direct_membership_project) do
        create(:todo, :pending,
          project: private_subgroup_with_direct_membership_project,
          user: member_user,
          target: create(:issue, project: private_subgroup_with_direct_membership_project)
        )
      end

      let_it_be(:mr_in_private_subgroup_with_direct_membership_project) do
        create(:merge_request,
          source_project: private_subgroup_with_direct_membership_project,
          assignees: [member_user]
        )
      end

      context 'with skipping of subresources' do
        subject(:execute_service) { described_class.new(user).execute(@group_member, skip_subresources: true) }

        before do
          execute_service
        end

        it 'removes the group membership' do
          expect(group.members.map(&:user)).not_to include(member_user)
        end

        it 'does not remove the project membership' do
          expect(group_project.members.map(&:user)).to include(member_user)
        end

        it 'does not remove the subgroup membership' do
          expect(subgroup.members.map(&:user)).to include(member_user)
        end

        it 'does not remove the subsubgroup membership' do
          expect(subsubgroup.members.map(&:user)).to include(member_user)
        end

        it 'does not remove the subsubproject membership' do
          expect(subsubproject.members.map(&:user)).to include(member_user)
        end

        it 'does not remove the user from the control project' do
          expect(control_project.members.map(&:user)).to include(user)
        end

        context 'todos', :sidekiq_inline do
          it 'removes todos for which the user no longer has access' do
            expect(member_user.todos).to include(
              todo_in_public_group_project,
              todo_in_public_subsubgroup_project,
              todo_in_private_subgroup_with_direct_membership_project
            )

            expect(member_user.todos).not_to include(todo_in_private_subgroup_project)
          end
        end

        context 'issuables', :sidekiq_inline do
          subject(:execute_service) do
            described_class.new(user).execute(@group_member, skip_subresources: true, unassign_issuables: true)
          end

          it 'removes assigned issuables, even in subresources' do
            expect(member_user.assigned_merge_requests).to be_empty
          end
        end
      end

      context 'without skipping of subresources' do
        subject(:execute_service) { described_class.new(user).execute(@group_member, skip_subresources: false) }

        before do
          execute_service
        end

        it 'removes the project membership' do
          expect(group_project.members.map(&:user)).not_to include(member_user)
        end

        it 'removes the group membership' do
          expect(group.members.map(&:user)).not_to include(member_user)
        end

        it 'removes the subgroup membership' do
          expect(subgroup.members.map(&:user)).not_to include(member_user)
        end

        it 'removes the subsubgroup membership' do
          expect(subsubgroup.members.map(&:user)).not_to include(member_user)
        end

        it 'removes the subsubproject membership' do
          expect(subsubproject.members.map(&:user)).not_to include(member_user)
        end

        it 'does not remove the user from the control project' do
          expect(control_project.members.map(&:user)).to include(user)
        end

        context 'todos', :sidekiq_inline do
          it 'removes todos for which the user no longer has access' do
            expect(member_user.todos).to include(
              todo_in_public_group_project,
              todo_in_public_subsubgroup_project
            )

            expect(member_user.todos).not_to include(
              todo_in_private_subgroup_project,
              todo_in_private_subgroup_with_direct_membership_project
            )
          end
        end

        context 'issuables', :sidekiq_inline do
          subject(:execute_service) do
            described_class.new(user).execute(@group_member, skip_subresources: false, unassign_issuables: true)
          end

          it 'removes assigned issuables' do
            expect(member_user.assigned_merge_requests).to be_empty
          end
        end
      end
    end

    context 'with invites' do
      before do
        create(:group_member, :developer, group: subsubgroup, user: member_user)
        create(:project_member, :invited, project: group_project, created_by: member_user)
        create(:group_member, :invited, group: group, created_by: member_user)
        create(:project_member, :invited, project: subsubproject, created_by: member_user)
        create(:group_member, :invited, group: subgroup, created_by: member_user)

        subsubproject.add_developer(member_user)
        control_project.add_maintainer(user)
        group.add_owner(user)

        @group_member = create(:group_member, :developer, group: group, user: member_user)
      end

      context 'with skipping of subresources' do
        before do
          described_class.new(user).execute(@group_member, skip_subresources: true)
        end

        it 'does not remove group members invited by deleted user' do
          expect(group.members.not_accepted_invitations_by_user(member_user)).not_to be_empty
        end

        it 'does not remove project members invited by deleted user' do
          expect(group_project.members.not_accepted_invitations_by_user(member_user)).not_to be_empty
        end

        it 'does not remove subgroup members invited by deleted user' do
          expect(subgroup.members.not_accepted_invitations_by_user(member_user)).not_to be_empty
        end

        it 'does not remove subproject members invited by deleted user' do
          expect(subsubproject.members.not_accepted_invitations_by_user(member_user)).not_to be_empty
        end
      end

      context 'without skipping of subresources' do
        before do
          described_class.new(user).execute(@group_member, skip_subresources: false)
        end

        it 'removes group members invited by deleted user' do
          expect(group.members.not_accepted_invitations_by_user(member_user)).to be_empty
        end

        it 'removes project members invited by deleted user' do
          expect(group_project.members.not_accepted_invitations_by_user(member_user)).to be_empty
        end

        it 'removes subgroup members invited by deleted user' do
          expect(subgroup.members.not_accepted_invitations_by_user(member_user)).to be_empty
        end

        it 'removes subproject members invited by deleted user' do
          expect(subsubproject.members.not_accepted_invitations_by_user(member_user)).to be_empty
        end
      end
    end
  end

  context 'deletion of invitations created by deleted project member' do
    let(:user) { project.first_owner }
    let(:member_user) { create(:user) }

    let(:project) { create(:project) }

    before do
      create(:project_member, :invited, project: project, created_by: member_user)

      project_member = create(:project_member, :maintainer, user: member_user, project: project)

      described_class.new(user).execute(project_member)
    end

    it 'removes project members invited by deleted user' do
      expect(project.members.not_accepted_invitations_by_user(member_user)).to be_empty
    end
  end

  describe '#mark_as_recursive_call' do
    it 'marks the instance as recursive' do
      service = described_class.new(current_user)
      service.mark_as_recursive_call

      expect(service.send(:recursive_call?)).to eq(true)
    end
  end

  context 'when member leaves their last group' do
    let_it_be(:group) { create(:group).tap { |g| g.add_owner(current_user) } }
    let(:member) { group.add_owner(member_user) }

    specify { expect(member.user.groups.count).to eq(1) }

    it_behaves_like 'a service destroying a member'
  end

  context 'when member leaves their last project' do
    let_it_be(:project) { create(:project).tap { |g| g.add_owner(current_user) } }
    let(:member) { project.add_owner(member_user) }

    specify { expect(member.user.projects.count).to eq(1) }

    it_behaves_like 'a service destroying a member'
  end
end
