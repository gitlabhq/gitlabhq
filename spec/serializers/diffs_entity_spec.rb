# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffsEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:options) do
    { request: request, merge_request: merge_request, merge_request_diffs: merge_request_diffs }
  end

  let(:entity) do
    described_class.new(merge_request_diffs.first.diffs, options)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'contains needed attributes' do
      expect(subject).to include(
        :real_size, :size, :branch_name,
        :target_branch_name, :commit, :merge_request_diff,
        :start_version, :latest_diff, :latest_version_path,
        :added_lines, :removed_lines, :render_overflow_warning,
        :email_patch_path, :plain_diff_path, :diff_files,
        :merge_request_diffs, :definition_path_prefix
      )
    end

    context "when a commit_id is passed" do
      let(:commits) { merge_request.commits }
      let(:entity) do
        described_class.new(
          merge_request_diffs.first.diffs,
          request: request,
          merge_request: merge_request,
          merge_request_diffs: merge_request_diffs,
          commit: commit
        )
      end

      subject { entity.as_json }

      context "when the passed commit is not the first or last in the group" do
        let(:commit) { commits.third }

        it 'includes commit references for previous and next' do
          expect(subject[:commit][:next_commit_id]).to eq(commits.second.id)
          expect(subject[:commit][:prev_commit_id]).to eq(commits.fourth.id)
        end
      end

      context "when the passed commit is the first in the group" do
        let(:commit) { commits.first }

        it 'includes commit references for nil and previous commit' do
          expect(subject[:commit][:next_commit_id]).to be_nil
          expect(subject[:commit][:prev_commit_id]).to eq(commits.second.id)
        end
      end

      context "when the passed commit is the last in the group" do
        let(:commit) { commits.last }

        it 'includes commit references for the next and nil' do
          expect(subject[:commit][:next_commit_id]).to eq(commits[-2].id)
          expect(subject[:commit][:prev_commit_id]).to be_nil
        end
      end
    end

    context 'when there are conflicts' do
      let(:diff_files) { merge_request_diffs.first.diffs.diff_files }
      let(:diff_file_with_conflict) { diff_files.to_a.last }
      let(:diff_file_without_conflict) { diff_files.to_a[-2] }

      let(:resolvable_conflicts) { true }
      let(:conflict_file) { double(our_path: diff_file_with_conflict.new_path) }
      let(:conflicts) { double(conflicts: double(files: [conflict_file]), can_be_resolved_in_ui?: resolvable_conflicts) }

      let(:merge_ref_head_diff) { true }
      let(:options) { super().merge(merge_ref_head_diff: merge_ref_head_diff) }

      before do
        allow(MergeRequests::Conflicts::ListService).to receive(:new).and_return(conflicts)
      end

      it 'conflicts are highlighted' do
        expect(conflict_file).to receive(:diff_lines_for_serializer)
        expect(diff_file_with_conflict).not_to receive(:diff_lines_for_serializer)
        expect(diff_file_without_conflict).to receive(:diff_lines_for_serializer).twice # for highlighted_diff_lines and is_fully_expanded

        subject
      end

      context 'merge ref head diff is not chosen to be displayed' do
        let(:merge_ref_head_diff) { false }

        it 'conflicts are not calculated' do
          expect(MergeRequests::Conflicts::ListService).not_to receive(:new)
        end
      end

      context 'when conflicts cannot be resolved' do
        let(:resolvable_conflicts) { false }

        it 'conflicts are not highlighted' do
          expect(conflict_file).not_to receive(:diff_lines_for_serializer)
          expect(diff_file_with_conflict).to receive(:diff_lines_for_serializer).twice  # for highlighted_diff_lines and is_fully_expanded
          expect(diff_file_without_conflict).to receive(:diff_lines_for_serializer).twice # for highlighted_diff_lines and is_fully_expanded

          subject
        end
      end
    end
  end
end
