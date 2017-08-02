require 'spec_helper'

describe IssuePolicy do
  let(:guest) { create(:user) }
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:reporter) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:reporter_from_group_link) { create(:user) }

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  context 'a private project' do
    let(:non_member) { create(:user) }
    let(:project) { create(:empty_project, :private) }
    let(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [author, :guest]
      project.team << [assignee, :guest]
      project.team << [reporter, :reporter]

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'does not allow non-members to read issues' do
      expect(permissions(non_member, issue)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      expect(permissions(non_member, issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to be_allowed(:read_issue)
      expect(permissions(guest, issue)).to be_disallowed(:update_issue, :admin_issue)

      expect(permissions(guest, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(guest, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect(permissions(reporter, issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter, issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows reporters from group links to read, update, and admin issues' do
      expect(permissions(reporter_from_group_link, issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter_from_group_link, issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect(permissions(author, issue)).to be_allowed(:read_issue, :update_issue)
      expect(permissions(author, issue)).to be_disallowed(:admin_issue)

      expect(permissions(author, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(author, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect(permissions(assignee, issue)).to be_allowed(:read_issue, :update_issue)
      expect(permissions(assignee, issue)).to be_disallowed(:admin_issue)

      expect(permissions(assignee, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(assignee, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow non-members to read confidential issues' do
        expect(permissions(non_member, confidential_issue)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(non_member, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(guest, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters from group links to read, update, and admin confidential issues' do
        expect(permissions(reporter_from_group_link, confidential_issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter_from_group_link, confidential_issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to be_allowed(:read_issue, :update_issue)
        expect(permissions(author, confidential_issue)).to be_disallowed(:admin_issue)

        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to be_allowed(:read_issue, :update_issue)
        expect(permissions(assignee, confidential_issue)).to be_disallowed(:admin_issue)

        expect(permissions(assignee, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end
    end
  end

  context 'a public project' do
    let(:project) { create(:empty_project, :public) }
    let(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [reporter, :reporter]

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to be_allowed(:read_issue)
      expect(permissions(guest, issue)).to be_disallowed(:update_issue, :admin_issue)

      expect(permissions(guest, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(guest, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect(permissions(reporter, issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter, issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows reporters from group links to read, update, and admin issues' do
      expect(permissions(reporter_from_group_link, issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter_from_group_link, issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect(permissions(author, issue)).to be_allowed(:read_issue, :update_issue)
      expect(permissions(author, issue)).to be_disallowed(:admin_issue)

      expect(permissions(author, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(author, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect(permissions(assignee, issue)).to be_allowed(:read_issue, :update_issue)
      expect(permissions(assignee, issue)).to be_disallowed(:admin_issue)

      expect(permissions(assignee, issue_no_assignee)).to be_allowed(:read_issue)
      expect(permissions(assignee, issue_no_assignee)).to be_disallowed(:update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(guest, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporter from group links to read, update, and admin confidential issues' do
        expect(permissions(reporter_from_group_link, confidential_issue)).to be_allowed(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter_from_group_link, confidential_issue_no_assignee)).to be_allowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to be_allowed(:read_issue, :update_issue)
        expect(permissions(author, confidential_issue)).to be_disallowed(:admin_issue)

        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to be_allowed(:read_issue, :update_issue)
        expect(permissions(assignee, confidential_issue)).to be_disallowed(:admin_issue)

        expect(permissions(assignee, confidential_issue_no_assignee)).to be_disallowed(:read_issue, :update_issue, :admin_issue)
      end
    end
  end
end
