require 'spec_helper'

describe Members::AuthorizedDestroyService do
  let(:member_user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:group_project) { create(:project, :public, group: group) }

  def number_of_assigned_issuables(user)
    Issue.assigned_to(user).count + MergeRequest.assigned_to(user).count
  end

  context 'Invited users' do
    # Regression spec for issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/32504
    it 'destroys invited project member' do
      project.add_developer(member_user)

      member = create :project_member, :invited, project: project

      expect { described_class.new(member, member_user).execute }
        .to change { Member.count }.from(3).to(2)
    end

    it "doesn't destroy invited project member notification_settings" do
      project.add_developer(member_user)

      member = create :project_member, :invited, project: project

      expect { described_class.new(member, member_user).execute }
        .not_to change { NotificationSetting.count }
    end

    it 'destroys invited group member' do
      group.add_developer(member_user)

      member = create :group_member, :invited, group: group

      expect { described_class.new(member, member_user).execute }
        .to change { Member.count }.from(2).to(1)
    end

    it "doesn't destroy invited group member notification_settings" do
      group.add_developer(member_user)

      member = create :group_member, :invited, group: group

      expect { described_class.new(member, member_user).execute }
        .not_to change { NotificationSetting.count }
    end
  end

  context 'Requested user' do
    it "doesn't destroy member notification_settings" do
      member = create(:project_member, user: member_user, requested_at: Time.now)

      expect { described_class.new(member, member_user).execute }
        .not_to change { NotificationSetting.count }
    end
  end

  context 'Group member' do
    let(:member) { group.members.find_by(user_id: member_user.id) }

    before do
      group.add_developer(member_user)
    end

    it "unassigns issues and merge requests" do
      issue = create :issue, project: group_project, assignees: [member_user]
      create :issue, assignees: [member_user]
      merge_request = create :merge_request, target_project: group_project, source_project: group_project, assignee: member_user
      create :merge_request, target_project: project, source_project: project, assignee: member_user

      expect { described_class.new(member, member_user).execute }
        .to change { number_of_assigned_issuables(member_user) }.from(4).to(2)

      expect(issue.reload.assignee_ids).to be_empty
      expect(merge_request.reload.assignee_id).to be_nil
    end

    it 'destroys member notification_settings' do
      group.add_developer(member_user)
      member = group.members.find_by(user_id: member_user.id)

      expect { described_class.new(member, member_user).execute }
        .to change { member_user.notification_settings.count }.by(-1)
    end
  end

  context 'Project member' do
    let(:member) { project.members.find_by(user_id: member_user.id) }

    before do
      project.add_developer(member_user)
    end

    it "unassigns issues and merge requests" do
      create :issue, project: project, assignees: [member_user]
      create :merge_request, target_project: project, source_project: project, assignee: member_user

      expect { described_class.new(member, member_user).execute }
        .to change { number_of_assigned_issuables(member_user) }.from(2).to(0)
    end

    it 'destroys member notification_settings' do
      expect { described_class.new(member, member_user).execute }
        .to change { member_user.notification_settings.count }.by(-1)
    end
  end
end
