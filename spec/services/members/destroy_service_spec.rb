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

  def number_of_assigned_issuables(user)
    Issue.assigned_to(user).count + MergeRequest.assigned_to(user).count
  end

  shared_examples 'a service destroying a member' do
    it 'destroys the member' do
      expect { described_class.new(current_user).execute(member, opts) }.to change { member.source.members_and_requesters.count }.by(-1)
    end

    it 'unassigns issues and merge requests' do
      if member.invite?
        expect { described_class.new(current_user).execute(member, opts) }
          .not_to change { number_of_assigned_issuables(member_user) }
      else
        create :issue, assignees: [member_user]
        issue = create :issue, project: group_project, assignees: [member_user]
        merge_request = create :merge_request, target_project: group_project, source_project: group_project, assignee: member_user

        expect { described_class.new(current_user).execute(member, opts) }
          .to change { number_of_assigned_issuables(member_user) }.from(3).to(1)

        expect(issue.reload.assignee_ids).to be_empty
        expect(merge_request.reload.assignee_id).to be_nil
      end
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

  shared_examples 'a service destroying an access requester' do
    it_behaves_like 'a service destroying a member'

    it 'calls Member#after_decline_request' do
      expect_any_instance_of(NotificationService).to receive(:decline_access_request).with(member)

      described_class.new(current_user).execute(member)
    end

    context 'when current user is the member' do
      it 'does not call Member#after_decline_request' do
        expect_any_instance_of(NotificationService).not_to receive(:decline_access_request).with(member)

        described_class.new(member_user).execute(member)
      end
    end
  end

  context 'with a member' do
    before do
      group_project.add_developer(member_user)
      group.add_developer(member_user)
    end

    context 'when current user cannot destroy the given member' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group_project.members.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { group_project.members.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group.members.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { group.members.find_by(user_id: member_user.id) }
      end
    end

    context 'when current user can destroy the given member' do
      before do
        group_project.add_master(current_user)
        group.add_owner(current_user)
      end

      it_behaves_like 'a service destroying a member' do
        let(:member) { group_project.members.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:member) { group.members.find_by(user_id: member_user.id) }
      end
    end
  end

  context 'with an access requester' do
    before do
      group_project.update_attributes(request_access_enabled: true)
      group.update_attributes(request_access_enabled: true)
      group_project.request_access(member_user)
      group.request_access(member_user)
    end

    context 'when current user cannot destroy the given access requester' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { group_project.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end

      it_behaves_like 'a service destroying a member' do
        let(:opts) { { skip_authorization: true } }
        let(:member) { group.requesters.find_by(user_id: member_user.id) }
      end
    end

    context 'when current user can destroy the given access requester' do
      before do
        group_project.add_master(current_user)
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
        group_project.add_master(current_user)
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
end
