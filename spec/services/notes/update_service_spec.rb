# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::UpdateService do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, group: group) }
  let(:private_group) { create(:group, :private) }
  let(:private_project) { create(:project, :private, group: private_group) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:issue) { create(:issue, project: project) }
  let(:issue2) { create(:issue, project: private_project) }
  let(:note) { create(:note, project: project, noteable: issue, author: user, note: "Old note #{user2.to_reference}") }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
    group.add_developer(user3)
    private_group.add_developer(user)
    private_group.add_developer(user2)
    private_project.add_developer(user3)
  end

  describe '#execute' do
    def update_note(opts)
      @note = Notes::UpdateService.new(project, user, opts).execute(note)
      @note.reload
    end

    it 'does not update the note when params is blank' do
      Timecop.freeze(1.day.from_now) do
        expect { update_note({}) }.not_to change { note.reload.updated_at }
      end
    end

    context 'suggestions' do
      it 'refreshes note suggestions' do
        markdown = <<-MARKDOWN.strip_heredoc
          ```suggestion
            foo
          ```

          ```suggestion
            bar
          ```
        MARKDOWN

        suggestion = create(:suggestion)
        note = suggestion.note

        expect { described_class.new(project, user, note: markdown).execute(note) }
          .to change { note.suggestions.count }.from(1).to(2)

        expect(note.suggestions.order(:relative_order).map(&:to_content))
          .to eq(["  foo\n", "  bar\n"])
      end
    end

    context 'todos' do
      shared_examples 'does not update todos' do
        it 'keep todos' do
          expect(todo.reload).to be_pending
        end

        it 'does not create any new todos' do
          expect(Todo.count).to eq(1)
        end
      end

      shared_examples 'creates one todo' do
        it 'marks todos as done' do
          expect(todo.reload).to be_done
        end

        it 'creates only 1 new todo' do
          expect(Todo.count).to eq(2)
        end
      end

      context 'when note includes a user mention' do
        let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

        context 'when the note does not change mentions' do
          before do
            update_note({ note: "Old note #{user2.to_reference}" })
          end

          it_behaves_like 'does not update todos'
        end

        context 'when the note changes to include one more user mention' do
          before do
            update_note({ note: "New note #{user2.to_reference} #{user3.to_reference}" })
          end

          it_behaves_like 'creates one todo'
        end

        context 'when the note changes to include a group mentions' do
          before do
            update_note({ note: "New note #{private_group.to_reference}" })
          end

          it_behaves_like 'creates one todo'
        end
      end

      context 'when note includes a group mention' do
        context 'when the group is public' do
          let(:note) { create(:note, project: project, noteable: issue, author: user, note: "Old note #{group.to_reference}") }
          let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

          context 'when the note does not change mentions' do
            before do
              update_note({ note: "Old note #{group.to_reference}" })
            end

            it_behaves_like 'does not update todos'
          end

          context 'when the note changes mentions' do
            before do
              update_note({ note: "New note #{user2.to_reference} #{user3.to_reference}" })
            end

            it_behaves_like 'creates one todo'
          end
        end

        context 'when the group is private' do
          let(:note) { create(:note, project: project, noteable: issue, author: user, note: "Old note #{private_group.to_reference}") }
          let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

          context 'when the note does not change mentions' do
            before do
              update_note({ note: "Old note #{private_group.to_reference}" })
            end

            it_behaves_like 'does not update todos'
          end

          context 'when the note changes mentions' do
            before do
              update_note({ note: "New note #{user2.to_reference} #{user3.to_reference}" })
            end

            it_behaves_like 'creates one todo'
          end
        end
      end
    end
  end
end
