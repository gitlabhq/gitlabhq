# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Suggestion do
  shared_examples 'correct suggestion raw content' do
    it 'returns correct raw data' do
      expect(suggestion.to_hash).to include(
        from_content: expected_lines.join,
        to_content: "#{text}\n",
        lines_above: above,
        lines_below: below
      )
    end

    it 'returns diff lines with correct line numbers' do
      diff_lines = suggestion.diff_lines

      expect(diff_lines).to all(be_a(Gitlab::Diff::Line))

      expected_diff_lines.each_with_index do |expected_line, index|
        expect(diff_lines[index].to_hash).to include(expected_line)
      end
    end
  end

  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 9,
      diff_refs: merge_request.diff_refs
    )
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
      let(:expected_diff_lines) do
        [
          { old_pos: 1, new_pos: 1, type: 'old', text: "-require 'fileutils'" },
          { old_pos: 2, new_pos: 1, type: 'old', text: "-require 'open3'" },
          { old_pos: 3, new_pos: 1, type: 'old', text: "-" },
          { old_pos: 4, new_pos: 1, type: 'old', text: "-module Popen" },
          { old_pos: 5, new_pos: 1, type: 'old', text: "-  extend self" },
          { old_pos: 6, new_pos: 1, type: 'old', text: "-" },
          { old_pos: 7, new_pos: 1, type: 'new', text: "+# parsed suggestion content" },
          { old_pos: 7, new_pos: 2, type: 'new', text: "+# with comments" }
        ]
      end

      it_behaves_like 'correct suggestion raw content'
    end

    context 'when changing content surpasses the amount of lines in the blob (bottom)' do
      let(:line) { 5 }
      let(:above) { 1 }
      let(:below) { blob_data.lines.size + 10 }
      let(:expected_below) { below }
      let(:expected_above) { above }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }
      let(:expected_diff_lines) do
        [
          { old_pos: 4, new_pos: 4, type: "match", text: "@@ -4 +4" },
          { old_pos: 4, new_pos: 4, type: "old", text: "-module Popen" },
          { old_pos: 5, new_pos: 4, type: "old", text: "-  extend self" },
          { old_pos: 6, new_pos: 4, type: "old", text: "-" },
          { old_pos: 7, new_pos: 4, type: "old", text: "-  def popen(cmd, path=nil)" },
          { old_pos: 8, new_pos: 4, type: "old", text: "-    unless cmd.is_a?(Array)" },
          { old_pos: 9, new_pos: 4, type: "old", text: "-      raise RuntimeError, \"System commands must be given as an array of strings\"" },
          { old_pos: 10, new_pos: 4, type: "old", text: "-    end" },
          { old_pos: 11, new_pos: 4, type: "old", text: "-" },
          { old_pos: 12, new_pos: 4, type: "old", text: "-    path ||= Dir.pwd" },
          { old_pos: 13, new_pos: 4, type: "old", text: "-" },
          { old_pos: 14, new_pos: 4, type: "old", text: "-    vars = {" },
          { old_pos: 15, new_pos: 4, type: "old", text: "-      \"PWD\" => path" },
          { old_pos: 16, new_pos: 4, type: "old", text: "-    }" },
          { old_pos: 17, new_pos: 4, type: "old", text: "-" },
          { old_pos: 18, new_pos: 4, type: "old", text: "-    options = {" },
          { old_pos: 19, new_pos: 4, type: "old", text: "-      chdir: path" },
          { old_pos: 20, new_pos: 4, type: "old", text: "-    }" },
          { old_pos: 21, new_pos: 4, type: "old", text: "-" },
          { old_pos: 22, new_pos: 4, type: "old", text: "-    unless File.directory?(path)" },
          { old_pos: 23, new_pos: 4, type: "old", text: "-      FileUtils.mkdir_p(path)" },
          { old_pos: 24, new_pos: 4, type: "old", text: "-    end" },
          { old_pos: 25, new_pos: 4, type: "old", text: "-" },
          { old_pos: 26, new_pos: 4, type: "old", text: "-    @cmd_output = \"\"" },
          { old_pos: 27, new_pos: 4, type: "old", text: "-    @cmd_status = 0" },
          { old_pos: 28, new_pos: 4, type: "old", text: "-" },
          { old_pos: 29, new_pos: 4, type: "old", text: "-    Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|" },
          { old_pos: 30, new_pos: 4, type: "old", text: "-      @cmd_output << stdout.read" },
          { old_pos: 31, new_pos: 4, type: "old", text: "-      @cmd_output << stderr.read" },
          { old_pos: 32, new_pos: 4, type: "old", text: "-      @cmd_status = wait_thr.value.exitstatus" },
          { old_pos: 33, new_pos: 4, type: "old", text: "-    end" },
          { old_pos: 34, new_pos: 4, type: "old", text: "-" },
          { old_pos: 35, new_pos: 4, type: "old", text: "-    return @cmd_output, @cmd_status" },
          { old_pos: 36, new_pos: 4, type: "old", text: "-  end" },
          { old_pos: 37, new_pos: 4, type: "old", text: "-end" },
          { old_pos: 38, new_pos: 4, type: "new", text: "+# parsed suggestion content" },
          { old_pos: 38, new_pos: 5, type: "new", text: "+# with comments" }
        ]
      end

      it_behaves_like 'correct suggestion raw content'
    end

    context 'when lines are within blob lines boundary' do
      let(:line) { 5 }
      let(:above) { 2 }
      let(:below) { 3 }
      let(:expected_below) { below }
      let(:expected_above) { above }
      let(:expected_lines) { blob_lines_data(line - expected_above, line + expected_below) }
      let(:expected_diff_lines) do
        [
          { old_pos: 3, new_pos: 3, type: "match", text: "@@ -3 +3" },
          { old_pos: 3, new_pos: 3, type: "old", text: "-" },
          { old_pos: 4, new_pos: 3, type: "old", text: "-module Popen" },
          { old_pos: 5, new_pos: 3, type: "old", text: "-  extend self" },
          { old_pos: 6, new_pos: 3, type: "old", text: "-" },
          { old_pos: 7, new_pos: 3, type: "old", text: "-  def popen(cmd, path=nil)" },
          { old_pos: 8, new_pos: 3, type: "old", text: "-    unless cmd.is_a?(Array)" },
          { old_pos: 9, new_pos: 3, type: "new", text: "+# parsed suggestion content" },
          { old_pos: 9, new_pos: 4, type: "new", text: "+# with comments" }
        ]
      end

      it_behaves_like 'correct suggestion raw content'
    end
  end
end
