# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::UpdateService, feature_category: :team_planning do
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

    context 'when the note is an invalid command' do
      let(:edit_note_text) { { note: '/spend asdf' } }

      it 'deletes the note and reports command errors' do
        updated_note = described_class.new(project, user, edit_note_text).execute(note)

        expect(updated_note.destroyed?).to eq(true)
        expect(updated_note.quick_actions_status.error?).to be(true)
        expect(updated_note.quick_actions_status.error_messages).to eq(['Commands did not apply'])
      end
    end

    context 'when the note is invalid' do
      let(:edit_note_text) { { note: 'new text' } }

      before do
        allow(note).to receive(:valid?).and_return(false)
      end

      it 'does not update the note' do
        travel_to(1.day.from_now) do
          expect { update_note(edit_note_text) }.not_to change { note.reload.updated_at }
        end
      end

      it 'returns the note' do
        expect(update_note(edit_note_text)).to eq(note)
      end
    end

    describe 'event tracking' do
      it 'does not track usage data when params is blank', :clean_gitlab_redis_shared_state do
        expect { update_note({}) }
          .to not_trigger_internal_events(
            Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_EDITED,
            Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter::MR_EDIT_COMMENT_ACTION,
            Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter::MR_EDIT_MULTILINE_COMMENT_ACTION
          ).and not_increment_usage_metrics(
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_monthly',
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_weekly',
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_weekly',
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_weekly'
          )
      end

      it 'tracks internal events and increments usage metrics', :clean_gitlab_redis_shared_state do
        expect { update_note(note: 'new text') }
          .to trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_EDITED)
            .with(project: project, user: user, category: 'InternalEventTracking')
          .and increment_usage_metrics(
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_monthly',
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_weekly'
          ).by(1)
          .and increment_usage_metrics(
            # Issue creation & update are performed by 2 different users
            'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
            'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly'
          ).by(2)
      end
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

      it 'checks for spam' do
        expect(note).to receive(:check_for_spam).with(action: :update, user: user)
        edit_note_text
      end

      it 'creates a webhook event' do
        expect(project).to receive(:execute_hooks)
        edit_note_text
      end

      context 'when quick action only update' do
        it "delete note and return commands_only error" do
          updated_note = described_class.new(project, user, { note: "/close\n" }).execute(note)

          expect(updated_note.destroyed?).to eq(true)
          expect(updated_note.errors).to match_array([
            "Note can't be blank"
          ])
          expect(updated_note.quick_actions_status.error?).to be(false)
          expect(updated_note.quick_actions_status.command_names).to eq(['close'])
          expect(updated_note.quick_actions_status.messages).to eq(['Closed this issue.'])
        end
      end

      context 'when existing note contains quick actions' do
        let!(:note) { create(:note, project: project, noteable: issue, author: user2, note: "foo\n/close\nbar") }

        before do
          update_note(edit_note_text)
          note.reload
          note.noteable.reload
        end

        context 'when a quick action exists in original note' do
          let(:edit_note_text) { { note: "foo\n/close\nbar\nbaz" } }

          it 'sanitizes/removes any quick actions and does not execute them' do
            expect(note.note).to eq "foo\nbar\nbaz"
            expect(note.noteable.open?).to be_truthy
          end
        end

        context 'when a new quick action is used in new note' do
          let(:edit_note_text) { { note: "bar\n/react :smile:\nfoo" } }

          it 'executes any quick actions not in unedited note' do
            expect(note.note).to eq "bar\nfoo"
            expect(note.noteable.award_emoji.first.name).to eq 'smile'
            expect(note.noteable.open?).to be_truthy
          end
        end
      end
    end

    context 'when note text was not changed' do
      let!(:note) { create(:note, project: project, noteable: issue, author: user2, note: "Old note #{user3.to_reference}") }
      let(:does_not_edit_note_text) { update_note({ note: note.note }) }

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

      it 'does not check for spam' do
        expect(note).not_to receive(:check_for_spam)
        does_not_edit_note_text
      end

      it 'does not create a webhook event' do
        expect(project).not_to receive(:execute_hooks)
        does_not_edit_note_text
      end
    end

    context 'when the notable is a merge request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:note) { create(:note, project: project, noteable: merge_request, author: user, note: "Old note #{user2.to_reference}") }

      it 'does not track usage data when params is blank', :clean_gitlab_redis_shared_state do
        expect { update_note({}) }
          .to not_increment_usage_metrics(
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_monthly',
            'redis_hll_counters.issues_edit.g_project_management_issue_comment_edited_weekly',
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_weekly',
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_weekly'
          )
      end

      it 'tracks merge request usage data', :clean_gitlab_redis_shared_state do
        expect { update_note(note: 'new text') }
          .to increment_usage_metrics(
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_mr_comment_weekly',
            'redis_hll_counters.code_review.code_review_total_unique_counts_monthly',
            'redis_hll_counters.code_review.code_review_total_unique_counts_weekly',
            'counts_monthly.aggregated_metrics.code_review_category_monthly_active_users',
            'counts_weekly.aggregated_metrics.code_review_category_monthly_active_users',
            'counts_monthly.aggregated_metrics.code_review_group_monthly_active_users',
            'counts_weekly.aggregated_metrics.code_review_group_monthly_active_users'
          ).and not_increment_usage_metrics(
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_monthly',
            'redis_hll_counters.code_review.i_code_review_user_edit_multiline_mr_comment_weekly'
          )
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

      let(:note) { create(:note, project: nil, noteable: snippet, author: user, note: "Note on a snippet with reference #{issue.to_reference}") }

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

      it 'does not create a webhook event' do
        expect(project).not_to receive(:execute_hooks)

        update_note(note: 'new text')
      end
    end
  end
end
