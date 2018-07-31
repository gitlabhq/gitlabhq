require 'spec_helper'

describe Todos::Destroy::ConfidentialIssueService do
  let(:project)        { create(:project, :public) }
  let(:user)           { create(:user) }
  let(:author)         { create(:user) }
  let(:assignee)       { create(:user) }
  let(:guest)          { create(:user) }
  let(:project_member) { create(:user) }
  let(:issue)          { create(:issue, project: project, author: author, assignees: [assignee]) }

  let!(:todo_issue_non_member)   { create(:todo, user: user, target: issue, project: project) }
  let!(:todo_issue_member)       { create(:todo, user: project_member, target: issue, project: project) }
  let!(:todo_issue_author)       { create(:todo, user: author, target: issue, project: project) }
  let!(:todo_issue_asignee)      { create(:todo, user: assignee, target: issue, project: project) }
  let!(:todo_issue_guest)        { create(:todo, user: guest, target: issue, project: project) }
  let!(:todo_another_non_member) { create(:todo, user: user, project: project) }

  describe '#execute' do
    before do
      project.add_developer(project_member)
      project.add_guest(guest)
    end

    subject { described_class.new(issue.id).execute }

    context 'when provided issue is confidential' do
      before do
        issue.update!(confidential: true)
      end

      it 'removes issue todos for a user who is not a project member' do
        expect { subject }.to change { Todo.count }.from(6).to(4)

        expect(user.todos).to match_array([todo_another_non_member])
        expect(author.todos).to match_array([todo_issue_author])
        expect(project_member.todos).to match_array([todo_issue_member])
      end
    end

    context 'when provided issue is not confidential' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end
  end
end
