# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::DestroyService do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }

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

    it 'tracks issue comment removal usage data', :clean_gitlab_redis_shared_state do
      note = create(:note, project: project, noteable: issue)
      event = Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_REMOVED
      counter = Gitlab::UsageDataCounters::HLLRedisCounter

      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_comment_removed_action).with(author: user).and_call_original
      expect do
        described_class.new(project, user).execute(note)
      end.to change { counter.unique_events(event_names: event, start_date: 1.day.ago, end_date: 1.day.from_now) }.by(1)
    end

    it 'tracks merge request usage data' do
      mr = create(:merge_request, source_project: project)
      note = create(:note, project: project, noteable: mr)
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).to receive(:track_remove_comment_action).with(note: note)

      described_class.new(project, user).execute(note)
    end

    context 'in a merge request' do
      let_it_be(:repo_project) { create(:project, :repository) }
      let_it_be(:merge_request) do
        create(:merge_request, source_project: repo_project,
               target_project: repo_project)
      end

      let_it_be(:note) do
        create(:diff_note_on_merge_request, project: repo_project,
               noteable: merge_request)
      end

      it 'does not track issue comment removal usage data' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_comment_removed_action)

        described_class.new(repo_project, user).execute(note)
      end

      context 'noteable highlight cache clearing' do
        before do
          allow(note.position).to receive(:unfolded_diff?) { true }
        end

        it 'clears noteable diff cache when it was unfolded for the note position' do
          expect(merge_request).to receive_message_chain(:diffs, :clear_cache)

          described_class.new(repo_project, user).execute(note)
        end

        it 'does not clear cache when note is not the first of the discussion' do
          reply_note = create(:diff_note_on_merge_request, in_reply_to: note,
                              project: repo_project,
                              noteable: merge_request)

          expect(merge_request).not_to receive(:diffs)

          described_class.new(repo_project, user).execute(reply_note)
        end
      end
    end
  end
end
