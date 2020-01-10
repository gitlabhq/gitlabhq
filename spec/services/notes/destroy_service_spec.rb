# frozen_string_literal: true

require 'spec_helper'

describe Notes::DestroyService do
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

    context 'noteable highlight cache clearing' do
      let(:repo_project) { create(:project, :repository) }
      let(:merge_request) do
        create(:merge_request, source_project: repo_project,
                               target_project: repo_project)
      end

      let(:note) do
        create(:diff_note_on_merge_request, project: repo_project,
                                            noteable: merge_request)
      end

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
