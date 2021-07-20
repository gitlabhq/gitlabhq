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
  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
      ```suggestion
        foo
      ```

      ```suggestion
        bar
      ```
    MARKDOWN
  end

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
      travel_to(1.day.from_now) do
        expect { update_note({}) }.not_to change { note.reload.updated_at }
      end
    end

    it 'does not track usage data when params is blank' do
      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_comment_edited_action)
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_edit_comment_action)

      update_note({})
    end

    it 'tracks issue usage data', :clean_gitlab_redis_shared_state do
      event = Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_EDITED
      counter = Gitlab::UsageDataCounters::HLLRedisCounter

      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_comment_edited_action).with(author: user).and_call_original
      expect do
        update_note(note: 'new text')
      end.to change { counter.unique_events(event_names: event, start_date: 1.day.ago, end_date: 1.day.from_now) }.by(1)
    end

    context 'when note text was changed' do
      let!(:note) { create(:note, project: project, noteable: issue, author: user2, note: "Old note #{user3.to_reference}") }
      let(:edit_note_text) { update_note({ note: 'new text' }) }

      it 'update last_edited_at' do
        travel_to(1.day.from_now) do
          expect { edit_note_text }.to change { note.reload.last_edited_at }
        end
      end

      it 'update updated_by' do
        travel_to(1.day.from_now) do
          expect { edit_note_text }.to change { note.reload.updated_by }
        end
      end
    end

    context 'when note text was not changed' do
      let!(:note) { create(:note, project: project, noteable: issue, author: user2, note: "Old note #{user3.to_reference}") }
      let(:does_not_edit_note_text) { update_note({}) }

      it 'does not update last_edited_at' do
        travel_to(1.day.from_now) do
          expect { does_not_edit_note_text }.not_to change { note.reload.last_edited_at }
        end
      end

      it 'does not update updated_by' do
        travel_to(1.day.from_now) do
          expect { does_not_edit_note_text }.not_to change { note.reload.updated_by }
        end
      end
    end

    context 'when the notable is a merge request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:note) { create(:note, project: project, noteable: merge_request, author: user, note: "Old note #{user2.to_reference}") }

      it 'tracks merge request usage data' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).to receive(:track_edit_comment_action).with(note: note)

        update_note(note: 'new text')
      end
    end

    context 'with system note' do
      before do
        note.update_column(:system, true)
      end

      it 'does not update the note' do
        expect { update_note(note: 'new text') }.not_to change { note.reload.note }
      end

      it 'does not track usage data' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_comment_edited_action)

        update_note(note: 'new text')
      end
    end

    context 'suggestions' do
      it 'refreshes note suggestions' do
        suggestion = create(:suggestion)
        note = suggestion.note

        expect { described_class.new(project, user, note: markdown).execute(note) }
          .to change { note.suggestions.count }.from(1).to(2)

        expect(note.suggestions.order(:relative_order).map(&:to_content))
          .to eq(["  foo\n", "  bar\n"])
      end
    end

    context 'setting confidentiality' do
      let(:opts) { { confidential: true } }

      context 'simple note' do
        it 'updates the confidentiality' do
          expect { update_note(opts) }.to change { note.reload.confidential }.from(nil).to(true)
        end
      end

      context 'discussion notes' do
        let(:note) { create(:discussion_note, project: project, noteable: issue, author: user, note: "Old note #{user2.to_reference}") }
        let!(:response_note_1) { create(:discussion_note, project: project, noteable: issue, in_reply_to: note) }
        let!(:response_note_2) { create(:discussion_note, project: project, noteable: issue, in_reply_to: note, confidential: false) }
        let!(:other_note) { create(:note, project: project, noteable: issue) }

        context 'when updating the root note' do
          it 'updates the confidentiality of the root note and all the responses' do
            update_note(opts)

            expect(note.reload.confidential).to be_truthy
            expect(response_note_1.reload.confidential).to be_truthy
            expect(response_note_2.reload.confidential).to be_truthy
            expect(other_note.reload.confidential).to be_falsey
          end
        end

        context 'when updating one of the response notes' do
          it 'updates only the confidentiality of the note that is being updated' do
            Notes::UpdateService.new(project, user, opts).execute(response_note_1)

            expect(note.reload.confidential).to be_falsey
            expect(response_note_1.reload.confidential).to be_truthy
            expect(response_note_2.reload.confidential).to be_falsey
            expect(other_note.reload.confidential).to be_falsey
          end
        end
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

    context 'for a personal snippet' do
      let_it_be(:snippet) { create(:personal_snippet, :public) }

      let(:note) { create(:note, project: nil, noteable: snippet, author: user, note: "Note on a snippet with reference #{issue.to_reference}" ) }

      it 'does not create todos' do
        expect { update_note({ note: "Mentioning user #{user2}" }) }.not_to change { note.todos.count }
      end

      it 'does not create suggestions' do
        expect { update_note({ note: "Updated snippet with markdown suggestion #{markdown}" }) }
          .not_to change { note.suggestions.count }
      end

      it 'does not create mentions' do
        expect(note).not_to receive(:create_new_cross_references!)
        update_note({ note: "Updated with new reference: #{issue.to_reference}" })
      end

      it 'does not track usage data' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_comment_edited_action)

        update_note(note: 'new text')
      end
    end
  end
end
