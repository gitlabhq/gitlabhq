# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::Suggestion do
  shared_examples 'correct suggestion raw content' do
    it 'returns correct raw data' do
      expect(suggestion.to_hash).to include(from_content: expected_lines.join,
                                            to_content: "#{text}\n",
                                            lines_above: above,
                                            lines_below: below)
    end
  end

  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:position) do
    Gitlab::Diff::Position.new(old_path: "files/ruby/popen.rb",
                               new_path: "files/ruby/popen.rb",
                               old_line: nil,
                               new_line: 9,
                               diff_refs: merge_request.diff_refs)
  end
  let(:diff_file) do
    position.diff_file(project.repository)
  end
  let(:text) { "# parsed suggestion content\n# with comments" }

  def blob_lines_data(from_line, to_line)
    diff_file.new_blob_lines_between(from_line, to_line)
  end

  def blob_data
    blob = diff_file.new_blob
    blob.load_all_data!
    blob.data
  end

  let(:suggestion) do
    described_class.new(text, line: line, above: above, below: below, diff_file: diff_file)
  end

  describe '#to_hash' do
    context 'when changing content surpasses the top limit' do
      let(:line) { 4 }
      let(:above) { 5 }
      let(:below) { 2 }
      let(:expected_above) { line - 1 }
      let(:expected_below) { below }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }

      it_behaves_like 'correct suggestion raw content'
    end

    context 'when changing content surpasses the amount of lines in the blob (bottom)' do
      let(:line) { 5 }
      let(:above) { 1 }
      let(:below) { blob_data.lines.size + 10 }
      let(:expected_below) { below }
      let(:expected_above) { above }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }

      it_behaves_like 'correct suggestion raw content'
    end

    context 'when lines are within blob lines boundary' do
      let(:line) { 5 }
      let(:above) { 2 }
      let(:below) { 3 }
      let(:expected_below) { below }
      let(:expected_above) { above }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }

      it_behaves_like 'correct suggestion raw content'
    end

    context 'when no extra lines (single-line suggestion)' do
      let(:line) { 5 }
      let(:above) { 0 }
      let(:below) { 0 }
      let(:expected_below) { below }
      let(:expected_above) { above }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }

      it_behaves_like 'correct suggestion raw content'
    end
  end
end
