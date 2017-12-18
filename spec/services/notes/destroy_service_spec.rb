require 'spec_helper'

describe Notes::DestroyService do
  set(:project) { create(:project, :public) }
  set(:issue) { create(:issue, project: project) }
  let(:user) { issue.author }

  describe '#execute' do
    it 'deletes a note' do
      note = create(:note, project: project, noteable: issue)

      described_class.new(project, user).execute(note)

      expect(project.issues.find(issue.id).notes).not_to include(note)
    end

    it 'updates the todo counts for users with todos for the note' do
      note = create(:note, project: project, noteable: issue)
      create(:todo, note: note, target: issue, user: user, author: user, project: project)

      expect { described_class.new(project, user).execute(note) }
        .to change { user.todos_pending_count }.from(1).to(0)
    end
  end
end
