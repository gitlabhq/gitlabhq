# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::ConfidentialIssueService, feature_category: :team_planning do
  let(:project)        { create(:project, :public) }
  let(:user)           { create(:user) }
  let(:author)         { create(:user) }
  let(:assignee)       { create(:user) }
  let(:guest)          { create(:user) }
  let(:project_member) { create(:user) }
  let(:issue_1)        { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }

  describe '#execute' do
    before do
      project.add_developer(project_member)
      project.add_guest(guest)

      # todos not to be deleted
      create(:todo, user: project_member, target: issue_1, project: project)
      create(:todo, user: author, target: issue_1, project: project)
      create(:todo, user: assignee, target: issue_1, project: project)
      create(:todo, user: user, project: project)
      # Todos to be deleted
      create(:todo, user: guest, target: issue_1, project: project)
      create(:todo, user: user, target: issue_1, project: project)
    end

    subject { described_class.new(issue_id: issue_1.id).execute }

    context 'when issue_id parameter is present' do
      context 'when provided issue is confidential' do
        it 'removes issue todos for users who can not access the confidential issue' do
          expect { subject }.to change { Todo.count }.from(6).to(4)
        end
      end

      context 'when provided issue is not confidential' do
        it 'does not remove any todos' do
          issue_1.update!(confidential: false)

          expect { subject }.not_to change { Todo.count }
        end
      end
    end

    context 'when project_id parameter is present' do
      subject { described_class.new(issue_id: nil, project_id: project.id).execute }

      it 'removes issues todos for users that cannot access confidential issues' do
        issue_2 = create(:issue, :confidential, project: project)
        issue_3 = create(:issue, :confidential, project: project, author: author, assignees: [assignee])
        issue_4 = create(:issue, project: project)
        # Todos not to be deleted
        create(:todo, user: guest, target: issue_1, project: project)
        create(:todo, user: assignee, target: issue_1, project: project)
        create(:todo, user: project_member, target: issue_2, project: project)
        create(:todo, user: author, target: issue_3, project: project)
        create(:todo, user: user, target: issue_4, project: project)
        create(:todo, user: user, project: project)
        # Todos to be deleted
        create(:todo, user: user, target: issue_1, project: project)
        create(:todo, user: guest, target: issue_2, project: project)

        expect { subject }.to change { Todo.count }.from(14).to(10)
      end
    end
  end
end
