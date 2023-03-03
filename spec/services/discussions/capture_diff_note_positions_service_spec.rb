# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussions::CaptureDiffNotePositionsService, feature_category: :code_review_workflow do
  context 'when merge request has a discussion' do
    let(:source_branch) { 'compare-with-merge-head-source' }
    let(:target_branch) { 'compare-with-merge-head-target' }
    let(:merge_request) { create(:merge_request, source_branch: source_branch, target_branch: target_branch) }
    let(:project) { merge_request.project }

    let(:offset) { 30 }
    let(:first_new_line) { 508 }
    let(:second_new_line) { 521 }
    let(:third_removed_line) { 1240 }

    let(:service) { described_class.new(merge_request) }

    def build_position(diff_refs, new_line: nil, old_line: nil)
      path = 'files/markdown/ruby-style-guide.md'
      Gitlab::Diff::Position.new(
        old_path: path, new_path: path, new_line: new_line, old_line: old_line, diff_refs: diff_refs)
    end

    def note_for(new_line: nil, old_line: nil)
      position = build_position(merge_request.diff_refs, new_line: new_line, old_line: old_line)
      create(:diff_note_on_merge_request, project: project, position: position, noteable: merge_request)
    end

    def verify_diff_note_position!(note, new_line: nil, old_line: nil)
      id, removed_line, added_line = note.line_code.split('_')

      expect(note.diff_note_positions.size).to eq(1)

      diff_position = note.diff_note_positions.last
      diff_refs = Gitlab::Diff::DiffRefs.new(
        base_sha: merge_request.target_branch_sha,
        start_sha: merge_request.target_branch_sha,
        head_sha: merge_request.merge_ref_head.sha)

      expect(diff_position.line_code).to eq("#{id}_#{removed_line.to_i - offset}_#{added_line}")
      expect(diff_position.position).to eq(build_position(diff_refs, new_line: new_line, old_line: old_line))
    end

    let!(:first_discussion_note) { note_for(new_line: first_new_line) }
    let!(:second_discussion_note) { note_for(new_line: second_new_line) }
    let!(:third_discussion_note) { note_for(old_line: third_removed_line) }
    let!(:second_discussion_another_note) do
      create(:diff_note_on_merge_request,
        project: project,
        position: second_discussion_note.position,
        discussion_id: second_discussion_note.discussion_id,
        noteable: merge_request)
    end

    context 'and position of the discussion changed on target branch head' do
      it 'diff positions are created for the first notes of the discussions' do
        MergeRequests::MergeToRefService.new(project: project, current_user: merge_request.author).execute(merge_request)
        service.execute

        verify_diff_note_position!(first_discussion_note, new_line: first_new_line)
        verify_diff_note_position!(second_discussion_note, new_line: second_new_line)
        verify_diff_note_position!(third_discussion_note, old_line: third_removed_line - offset)

        expect(second_discussion_another_note.diff_note_positions).to be_empty
      end
    end
  end
end
