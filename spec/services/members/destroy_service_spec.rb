# frozen_string_literal: true

require 'spec_helper'

describe Members::DestroyService do
  let(:current_user) { create(:user) }
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
    end

    it 'destroys the member' do
      expect { described_class.new(current_user).execute(member, opts) }.to change { member.source.members_and_requesters.count }.by(-1)
    end

    it 'destroys member notification_settings' do
      if member_user.notification_settings.any?
        expect { described_class.new(current_user).execute(member, opts) }
          .to change { member_user.notification_settings.count }.by(-1)
      else
        expect { described_class.new(current_user).execute(member, opts) }
          .not_to change { member_user.notification_settings.count }
      end
    end
  end

  shared_examples 'a service destroying a member with access' do
    it_behaves_like 'a service destroying a member'

    it 'invalidates cached counts for assigned issues and merge requests', :aggregate_failures do
      create(:issue, project: group_project, assignees: [member_user])
      create(:merge_request, source_project: group_project, assignees: [member_user])
      create(:todo, :pending, project: group_project, user: member_user)
      create(:todo, :done, project: group_project, user: member_user)

      expect(member_user.assigned_open_merge_requests_count).to be(1)
      expect(member_user.assigned_open_issues_count).to be(1)
      expect(member_user.todos_pending_count).to be(1)
      expect(member_user.todos_done_count).to be(1)

      described_class.new(current_user).execute(member, opts)

      expect(member_user.assigned_open_merge_requests_count).to be(0)
      expect(member_user.assigned_open_issues_count).to be(0)
      expect(member_user.todos_pending_count).to be(0)
      expect(member_user.todos_done_count).to be(0)
    end
  end

  shared_examples 'a service destroying an access requester' do
    it_behaves_like 'a service destroying a member'

    it 'calls Member#after_decline_request' do
      expect_any_instance_of(NotificationService).to receive(:decline_access_request).with(member)

      described_class.new(current_user).execute(member, opts)
    end

    context 'when current user is the member' do
      it 'does not call Member#after_decline_request' do
        expect_any_instance_of(NotificationService).not_to receive(:decline_access_request).with(member)

        described_class.new(member_user).execute(member, opts)
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

        before do
          group_project.add_developer(member_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'

        it_behaves_like 'a service destroying a member with access' do
          let(:opts) { { skip_authorization: true } }
        end
      end

      context 'with a group member' do
        let(:member) { group.members.find_by(user_id: member_user.id) }

        before do
          group.add_developer(member_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'

        it_behaves_like 'a service destroying a member with access' do
          let(:opts) { { skip_authorization: true } }
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
      end

      context 'with a group member' do
        let(:member) { group.members.find_by(user_id: member_user.id) }

        before do
          group.add_developer(member_user)
        end

        it_behaves_like 'a service destroying a member with access'
      end
    end
  end

  context 'with an access requester' do
    before do
      group_project.update(request_access_enabled: true)
      group.update(request_access_enabled: true)
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

      it_behaves_like 'a service destroying an access requester' do
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying an access requester' do
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

      # Regression spec for issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/32504
      it_behaves_like 'a service destroying a member' do
        let(:member) { project_invited_member }
      end

      it_behaves_like 'a service destroying a member' do
        let(:member) { group_invited_member }
      end
    end
  end

  context 'subresources' do
    let(:user) { create(:user) }
    let(:member_user) { create(:user) }
    let(:opts) { {} }

    let(:group) { create(:group, :public) }
    let(:subgroup) { create(:group, parent: group) }
    let(:subsubgroup) { create(:group, parent: subgroup) }
    let(:subsubproject) { create(:project, group: subsubgroup) }

    let(:group_project) { create(:project, :public, group: group) }
    let(:control_project) { create(:project, group: subsubgroup) }

    before do
      create(:group_member, :developer, group: subsubgroup, user: member_user)

      subsubproject.add_developer(member_user)
      control_project.add_maintainer(user)
      group.add_owner(user)

      group_member = create(:group_member, :developer, group: group, user: member_user)

      described_class.new(user).execute(group_member, opts)
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
  end
end
