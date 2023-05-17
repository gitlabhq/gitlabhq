# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussions::UpdateDiffPositionService, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:current_user) { project.first_owner }
  let(:create_commit) { project.commit("913c66a37b4a45b9769037c55c2d238bd0942d2e") }
  let(:modify_commit) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
  let(:edit_commit) { project.commit("570e7b2abdd848b95f2f578043fc23bd6f6fd24d") }

  let(:path) { "files/ruby/popen.rb" }

  let(:old_diff_refs) do
    Gitlab::Diff::DiffRefs.new(
      base_sha: create_commit.parent_id,
      head_sha: modify_commit.sha
    )
  end

  let(:new_diff_refs) do
    Gitlab::Diff::DiffRefs.new(
      base_sha: create_commit.parent_id,
      head_sha: edit_commit.sha
    )
  end

  subject do
    described_class.new(
      project,
      current_user,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: [path]
    )
  end

  # old diff:
  #     1 + require 'fileutils'
  #     2 + require 'open3'
  #     3 +
  #     4 + module Popen
  #     5 +   extend self
  #     6 +
  #     7 +   def popen(cmd, path=nil)
  #     8 +     unless cmd.is_a?(Array)
  #     9 +       raise "System commands must be given as an array of strings"
  #    10 +     end
  #    11 +
  #    12 +     path ||= Dir.pwd
  #    13 +     vars = { "PWD" => path }
  #    14 +     options = { chdir: path }
  #    15 +
  #    16 +     unless File.directory?(path)
  #    17 +       FileUtils.mkdir_p(path)
  #    18 +     end
  #    19 +
  #    20 +     @cmd_output = ""
  #    21 +     @cmd_status = 0
  #    22 +     Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
  #    23 +       @cmd_output << stdout.read
  #    24 +       @cmd_output << stderr.read
  #    25 +       @cmd_status = wait_thr.value.exitstatus
  #    26 +     end
  #    27 +
  #    28 +     return @cmd_output, @cmd_status
  #    29 +   end
  #    30 + end
  #
  # new diff:
  #     1 + require 'fileutils'
  #     2 + require 'open3'
  #     3 +
  #     4 + module Popen
  #     5 +   extend self
  #     6 +
  #     7 +   def popen(cmd, path=nil)
  #     8 +     unless cmd.is_a?(Array)
  #     9 +       raise RuntimeError, "System commands must be given as an array of strings"
  #    10 +     end
  #    11 +
  #    12 +     path ||= Dir.pwd
  #    13 +
  #    14 +     vars = {
  #    15 +       "PWD" => path
  #    16 +     }
  #    17 +
  #    18 +     options = {
  #    19 +       chdir: path
  #    20 +     }
  #    21 +
  #    22 +     unless File.directory?(path)
  #    23 +       FileUtils.mkdir_p(path)
  #    24 +     end
  #    25 +
  #    26 +     @cmd_output = ""
  #    27 +     @cmd_status = 0
  #    28 +
  #    29 +     Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
  #    30 +       @cmd_output << stdout.read
  #    31 +       @cmd_output << stderr.read
  #    32 +       @cmd_status = wait_thr.value.exitstatus
  #    33 +     end
  #    34 +
  #    35 +     return @cmd_output, @cmd_status
  #    36 +   end
  #    37 + end
  #
  # old->new diff:
  # .. .. @@ -6,12 +6,18 @@ module Popen
  #  6  6
  #  7  7    def popen(cmd, path=nil)
  #  8  8      unless cmd.is_a?(Array)
  #  9    -      raise "System commands must be given as an array of strings"
  #     9 +      raise RuntimeError, "System commands must be given as an array of strings"
  # 10 10      end
  # 11 11
  # 12 12      path ||= Dir.pwd
  # 13    -    vars = { "PWD" => path }
  # 14    -    options = { chdir: path }
  #    13 +
  #    14 +    vars = {
  #    15 +      "PWD" => path
  #    16 +    }
  #    17 +
  #    18 +    options = {
  #    19 +      chdir: path
  #    20 +    }
  # 15 21
  # 16 22      unless File.directory?(path)
  # 17 23        FileUtils.mkdir_p(path)
  # 18 24      end
  # 19 25
  # 20 26      @cmd_output = ""
  # 21 27      @cmd_status = 0
  #    28 +
  # 22 29      Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
  # 23 30        @cmd_output << stdout.read
  # 24 31        @cmd_output << stderr.read
  # .. ..

  describe "#execute" do
    let(:discussion) { create(:diff_note_on_merge_request, project: project, position: old_position).to_discussion }

    let(:old_position) do
      Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        old_line: nil,
        new_line: line,
        diff_refs: old_diff_refs
      )
    end

    shared_examples 'outdated diff note' do
      it "doesn't update the position" do
        subject.execute(discussion)

        expect(discussion.original_position).to eq(old_position)
        expect(discussion.position).to eq(old_position)
      end

      it 'sets the change position' do
        subject.execute(discussion)

        change_position = discussion.change_position
        expect(change_position.start_sha).to eq(old_diff_refs.head_sha)
        expect(change_position.head_sha).to eq(new_diff_refs.head_sha)
        expect(change_position.formatter.old_line).to eq(9)
        expect(change_position.formatter.new_line).to be_nil
      end

      it 'creates a system discussion' do
        expect(SystemNoteService).to receive(:diff_discussion_outdated).with(
          discussion, project, current_user, instance_of(Gitlab::Diff::Position))

        subject.execute(discussion)
      end
    end

    context "when the diff line is the same" do
      let(:line) { 16 }

      it "updates the position" do
        subject.execute(discussion)

        expect(discussion.original_position).to eq(old_position)
        expect(discussion.position).not_to eq(old_position)
        expect(discussion.position.formatter.new_line).to eq(22)
      end

      context 'when the resolve_outdated_diff_discussions setting is set' do
        before do
          project.update!(resolve_outdated_diff_discussions: true)
        end

        it 'does not resolve the discussion' do
          subject.execute(discussion)

          expect(discussion).not_to be_resolved
          expect(discussion).not_to be_resolved_by_push
        end
      end
    end

    context "when the diff line has changed" do
      let(:line) { 9 }

      include_examples 'outdated diff note'

      context 'when the resolve_outdated_diff_discussions setting is set' do
        before do
          project.update!(resolve_outdated_diff_discussions: true)
        end

        it 'sets resolves the discussion and sets resolved_by_push' do
          subject.execute(discussion)

          expect(discussion).to be_resolved
          expect(discussion).to be_resolved_by_push
        end

        include_examples 'outdated diff note'
      end
    end
  end
end
