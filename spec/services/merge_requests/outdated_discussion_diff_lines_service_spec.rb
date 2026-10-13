# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::OutdatedDiscussionDiffLinesService, feature_category: :code_review_workflow do
  include PositionTracerHelpers

  let(:project) { create(:project, :small_repo) }
  let(:current_user) { project.first_owner }
  let(:branch_name) { 'outdated-lines-test' }
  let(:file_name) { 'test-file' }

  let(:merge_request) do
    create_branch(branch_name, 'master')
    create_file(branch_name, file_name, "A\nB\nC\nD\nE\nF\n")

    create(:merge_request, source_project: project, source_branch: branch_name, target_branch: 'master')
  end

  describe '#execute' do
    let(:diff_refs) { merge_request.diff_refs }
    let(:line_range_endpoint) do
      {
        'line_code' => position(new_path: file_name, new_line: 2).line_code(project.repository),
        'type' => 'new',
        'old_line' => nil,
        'new_line' => 2
      }
    end

    let!(:discussion) do
      create(
        :diff_note_on_merge_request,
        project: project,
        noteable: merge_request,
        position: position(
          new_path: file_name,
          new_line: 2,
          line_range: { 'start' => line_range_endpoint, 'end' => line_range_endpoint }
        )
      ).to_discussion
    end

    def position(attrs)
      Gitlab::Diff::Position.new(attrs.reverse_merge(diff_refs: diff_refs))
    end

    def push(content)
      update_file(branch_name, file_name, content)
      MergeRequests::ReloadDiffsService.new(MergeRequest.find(merge_request.id), current_user).execute
    end

    subject(:lines) do
      system_note = merge_request.notes.system.find_by(discussion_id: discussion.id)

      described_class.new(project: project, note: system_note).execute.map(&:text)
    end

    context 'when a push moved the line before another push changed it' do
      before do
        push("1\n2\n3\n4\n5\n6\n7\n8\nA\nB\nC\nD\nE\nF\n")
        push("1\n2\n3\n4\n5\n6\n7\n8\nA\nBB\nC\nD\nE\nF\n")
      end

      it 'returns the lines around the change' do
        expect(lines).to eq([' A', '-B', '+BB', ' C', ' D'])
      end
    end
  end
end
