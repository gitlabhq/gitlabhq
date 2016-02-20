require 'spec_helper'

describe Notes::UpdateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:note) { create(:note, project: project, noteable: issue, author: user, note: 'Old note') }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe '#execute' do
    def update_note(opts)
      @note = Notes::UpdateService.new(project, user, opts).execute(note)
      @note.reload
    end

    context 'todos' do
      let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

      context 'when the note change' do
        before do
          update_note({ note: 'New note' })
        end

        it 'marks todos as done' do
          expect(todo.reload).to be_done
        end
      end

      context 'when the note does not change' do
        before do
          update_note({ note: 'Old note' })
        end

        it 'keep todos' do
          expect(todo.reload).to be_pending
        end
      end
    end
  end
end
