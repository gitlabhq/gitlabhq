# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Suggestions::OutdateService, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.target_project }
    let(:user) { merge_request.author }
    let(:file_path) { 'files/ruby/popen.rb' }
    let(:branch_name) { project.default_branch }
    let(:diff_file) { suggestion.diff_file }
    let(:position) { build_position(file_path, comment_line) }
    let(:note) do
      create(
        :diff_note_on_merge_request,
        noteable: merge_request,
        position: position,
        project: project
      )
    end

    def build_position(path, line)
      Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        old_line: nil,
        new_line: line,
        diff_refs: merge_request.diff_refs
      )
    end

    def commit_changes(file_path, new_content)
      params = {
        file_path: file_path,
        commit_message: "Update File",
        file_content: new_content,
        start_project: project,
        start_branch: project.default_branch,
        branch_name: branch_name
      }

      Files::UpdateService.new(project, user, params).execute
    end

    def update_file_line(diff_file, change_line, content)
      new_lines = diff_file.new_blob.data.lines
      new_lines[change_line..change_line] = content
      result = commit_changes(diff_file.file_path, new_lines.join)
      newrev = result[:result]

      expect(result[:status]).to eq(:success)
      expect(newrev).to be_present

      # Ensure all memoized data is cleared in order
      # to generate the new merge_request_diff.
      MergeRequest.find(merge_request.id).reload_diff(user)

      note.reload
    end

    before do
      project.add_maintainer(user)
    end

    subject { described_class.new.execute(merge_request) }

    context 'when there is a change within multi-line suggestion range' do
      let(:comment_line) { 9 }
      let(:lines_above) { 8 } # suggesting to change lines 1..9
      let(:change_line) { 2 } # line 2 is within the range
      let!(:suggestion) do
        create(:suggestion, :content_from_repo, note: note, lines_above: lines_above)
      end

      it 'updates the outdatable suggestion record' do
        update_file_line(diff_file, change_line, "# foo\nbar\n")

        # Make sure note is still active
        expect(note.active?).to be(true)

        expect { subject }.to change { suggestion.reload.outdated }
          .from(false).to(true)
      end
    end

    context 'when there is no change within multi-line suggestion range' do
      let(:comment_line) { 9 }
      let(:lines_above) { 3 } # suggesting to change lines 6..9
      let(:change_line) { 2 } # line 2 is not within the range
      let!(:suggestion) do
        create(:suggestion, :content_from_repo, note: note, lines_above: lines_above)
      end

      subject { described_class.new.execute(merge_request) }

      it 'does not outdates suggestion record' do
        update_file_line(diff_file, change_line, "# foo\nbar\n")

        # Make sure note is still active
        expect(note.active?).to be(true)

        expect { subject }.not_to change { suggestion.reload.outdated }.from(false)
      end
    end
  end
end
