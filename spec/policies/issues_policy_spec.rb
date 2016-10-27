require 'spec_helper'

describe IssuePolicy, models: true do
  let(:guest) { create(:user) }
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:reporter) { create(:user) }

  def permissions(user, issue)
    IssuePolicy.abilities(user, issue).to_set
  end

  context 'a private project' do
    let(:non_member) { create(:user) }
    let(:project) { create(:empty_project, :private) }
    let(:issue) { create(:issue, project: project, assignee: assignee, author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [author, :guest]
      project.team << [assignee, :guest]
      project.team << [reporter, :reporter]
    end

    it 'does not allow non-members to read issues' do
      expect(permissions(non_member, issue)).not_to include(:read_issue, :update_issue, :admin_issue)
      expect(permissions(non_member, issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to include(:read_issue)
      expect(permissions(guest, issue)).not_to include(:update_issue, :admin_issue)

      expect(permissions(guest, issue_no_assignee)).to include(:read_issue)
      expect(permissions(guest, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect(permissions(reporter, issue)).to include(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter, issue_no_assignee)).to include(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect(permissions(author, issue)).to include(:read_issue, :update_issue)
      expect(permissions(author, issue)).not_to include(:admin_issue)

      expect(permissions(author, issue_no_assignee)).to include(:read_issue)
      expect(permissions(author, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect(permissions(assignee, issue)).to include(:read_issue, :update_issue)
      expect(permissions(assignee, issue)).not_to include(:admin_issue)

      expect(permissions(assignee, issue_no_assignee)).to include(:read_issue)
      expect(permissions(assignee, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignee: assignee, author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow non-members to read confidential issues' do
        expect(permissions(non_member, confidential_issue)).not_to include(:read_issue, :update_issue, :admin_issue)
        expect(permissions(non_member, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).not_to include(:read_issue, :update_issue, :admin_issue)
        expect(permissions(guest, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to include(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to include(:read_issue, :update_issue)
        expect(permissions(author, confidential_issue)).not_to include(:admin_issue)

        expect(permissions(author, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to include(:read_issue, :update_issue)
        expect(permissions(assignee, confidential_issue)).not_to include(:admin_issue)

        expect(permissions(assignee, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end
    end
  end

  context 'a public project' do
    let(:project) { create(:empty_project, :public) }
    let(:issue) { create(:issue, project: project, assignee: assignee, author: author) }
    let(:issue_no_assignee) { create(:issue, project: project) }

    before do
      project.team << [guest, :guest]
      project.team << [reporter, :reporter]
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to include(:read_issue)
      expect(permissions(guest, issue)).not_to include(:update_issue, :admin_issue)

      expect(permissions(guest, issue_no_assignee)).to include(:read_issue)
      expect(permissions(guest, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    it 'allows reporters to read, update, and admin issues' do
      expect(permissions(reporter, issue)).to include(:read_issue, :update_issue, :admin_issue)
      expect(permissions(reporter, issue_no_assignee)).to include(:read_issue, :update_issue, :admin_issue)
    end

    it 'allows issue authors to read and update their issues' do
      expect(permissions(author, issue)).to include(:read_issue, :update_issue)
      expect(permissions(author, issue)).not_to include(:admin_issue)

      expect(permissions(author, issue_no_assignee)).to include(:read_issue)
      expect(permissions(author, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    it 'allows issue assignees to read and update their issues' do
      expect(permissions(assignee, issue)).to include(:read_issue, :update_issue)
      expect(permissions(assignee, issue)).not_to include(:admin_issue)

      expect(permissions(assignee, issue_no_assignee)).to include(:read_issue)
      expect(permissions(assignee, issue_no_assignee)).not_to include(:update_issue, :admin_issue)
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignee: assignee, author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).not_to include(:read_issue, :update_issue, :admin_issue)
        expect(permissions(guest, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to include(:read_issue, :update_issue, :admin_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to include(:read_issue, :update_issue)
        expect(permissions(author, confidential_issue)).not_to include(:admin_issue)

        expect(permissions(author, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to include(:read_issue, :update_issue)
        expect(permissions(assignee, confidential_issue)).not_to include(:admin_issue)

        expect(permissions(assignee, confidential_issue_no_assignee)).not_to include(:read_issue, :update_issue, :admin_issue)
      end
    end
  end
end
