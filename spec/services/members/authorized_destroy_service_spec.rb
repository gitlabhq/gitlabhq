require 'spec_helper'

describe Members::AuthorizedDestroyService, services: true do
  let(:user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let(:group) { create(:group, :public) }
  let(:group_project) { create(:empty_project, :public, group: group) }

  def number_of_assigned_issuables(user)
    user.assigned_issues.count + user.assigned_merge_requests.count
  end

  context 'Group member' do
    it "unassigns issues and merge requests" do
      group.add_developer(member_user)

      issue = create :issue, project: group_project, assignee: member_user
      create :issue, assignee: member_user
      merge_request = create :merge_request, target_project: group_project, source_project: group_project, assignee: member_user
      create :merge_request, target_project: project, source_project: project, assignee: member_user

      member = group.members.find_by(user_id: member_user.id)

      expect{ described_class.new(member, member_user).execute }
        .to change{ number_of_assigned_issuables(member_user) }.from(4).to(2)

      expect(issue.reload.assignee_id).to be_nil
      expect(merge_request.reload.assignee_id).to be_nil
    end
  end

  context 'Project member' do
    it "unassigns issues and merge requests" do
      project.team << [member_user, :developer]

      create :issue, project: project, assignee: member_user
      create :merge_request, target_project: project, source_project: project, assignee: member_user

      member = project.members.find_by(user_id: member_user.id)

      expect{ described_class.new(member, member_user).execute }
        .to change{ number_of_assigned_issuables(member_user) }.from(2).to(0)
    end
  end
end
