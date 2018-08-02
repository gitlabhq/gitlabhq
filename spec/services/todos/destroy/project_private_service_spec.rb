require 'spec_helper'

describe Todos::Destroy::ProjectPrivateService do
  let(:project)            { create(:project, :public) }
  let(:user)               { create(:user) }
  let(:project_member)     { create(:user) }
  let(:guest)              { create(:user) }
  let(:issue)              { create(:issue, project: project) }
  let(:confidential_issue) { create(:issue, confidential: true, project: project) }

  let!(:todo_issue_non_member)     { create(:todo, user: user, project: project, target: issue) }
  let!(:todo_issue_guest)          { create(:todo, user: guest, project: project, target: issue) }
  let!(:todo_issue_member)         { create(:todo, user: project_member, project: project, target: issue) }
  let!(:todo_conf_issue_non_guest) { create(:todo, user: user, project: project, target: confidential_issue) }
  let!(:todo_conf_issue_guest)     { create(:todo, user: guest, project: project, target: confidential_issue) }
  let!(:todo_conf_issue_member)    { create(:todo, user: project_member, project: project, target: confidential_issue) }
  let!(:todo_another_non_member)   { create(:todo, user: user, project: project) }

  describe '#execute' do
    before do
      project.add_developer(project_member)
      project.add_guest(guest)
    end

    subject { described_class.new(project.id).execute }

    context 'when a project set to private' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'removes todos of non members and confidential issue todos of guests' do
        expect { subject }.to change { Todo.count }.from(7).to(3)

        expect(user.todos).to be_empty
        expect(guest.todos).to match_array([todo_issue_guest])
        expect(project_member.todos).to match_array([todo_issue_member, todo_conf_issue_member])
      end
    end

    context 'when project is not private' do
      it 'removes only confidential issue todos for guests and non members' do
        expect { subject }.to change { Todo.count }.from(7).to(5)
      end
    end
  end
end
