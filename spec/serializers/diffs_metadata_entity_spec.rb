# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffsMetadataEntity, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:merge_request_diff) { merge_request_diffs.last }
  let(:options) { {} }

  let(:entity) do
    described_class.new(
      merge_request_diff.diffs,
      options.merge(
        request: request,
        merge_request: merge_request,
        merge_request_diffs: merge_request_diffs
      )
    )
  end

  context 'as json' do
    subject { entity.as_json }

    it 'contain only required attributes' do
      expect(subject.keys).to contain_exactly(
        # Inherited attributes
        :real_size, :size, :branch_name,
        :target_branch_name, :commit, :merge_request_diff,
        :start_version, :latest_diff, :latest_version_path,
        :added_lines, :removed_lines, :render_overflow_warning,
        :email_patch_path, :plain_diff_path,
        :merge_request_diffs, :context_commits, :context_commits_diff,
        :definition_path_prefix, :source_branch_exists,
        :can_merge, :conflict_resolution_path, :has_conflicts,
        :project_name, :project_path, :user_full_name, :username,
        :has_encoded_file_paths,
        # Attributes
        :diff_files
      )
    end

    describe 'diff_files' do
      let!(:raw_diff_files) { merge_request_diff.diffs.raw_diff_files }

      before do
        expect_next_instance_of(Gitlab::Diff::FileCollection::MergeRequestDiff) do |instance|
          # Use lightweight version instead. Several methods delegate to it, so putting a 5
          # calls limit.
          expect(instance).to receive(:raw_diff_files).at_most(5).times.and_call_original
          expect(instance).not_to receive(:diff_files)
        end
      end

      it 'serializes diff files metadata using DiffFileMetadataEntity' do
        expect(DiffFileMetadataEntity)
          .to receive(:represent)
          .with(
            raw_diff_files,
            hash_including(options.merge(conflicts: nil))
          )

        subject[:diff_files]
      end

      context 'when there are conflicts' do
        before do
          allow(entity).to receive(:conflicts_with_types).and_return({
            raw_diff_files.first.new_path => {
              conflict_type: :both_modified,
              conflict_type_when_renamed: :both_modified
            }
          })
        end

        it 'serializes diff files with conflicts' do
          expect(DiffFileMetadataEntity)
            .to receive(:represent)
            .with(
              raw_diff_files,
              hash_including(options.merge(conflicts: entity.conflicts_with_types))
            )

          subject[:diff_files]
        end
      end
    end

    describe 'has_encoded_file_paths' do
      context 'when only_context_commits is true' do
        let(:context_commits_diff) do
          instance_double(
            ContextCommitsDiff,
            commits_count: 1,
            merge_request: merge_request
          )
        end

        let(:options) { { only_context_commits: true } }

        it 'calls ContextCommitsDiff#has_encoded_file_paths?' do
          allow(merge_request)
            .to receive(:context_commits_diff)
            .and_return(context_commits_diff)

          expect(context_commits_diff).to receive(:has_encoded_file_paths?).and_return(true)
          expect(subject[:has_encoded_file_paths]).to eq(true)
        end
      end

      context 'when only_context_commits is not set' do
        context 'when merge_request_diff is present' do
          let(:options) { { merge_request_diff: merge_request_diff } }

          it 'calls MergeRequestDiff#has_encoded_file_paths?' do
            expect(merge_request_diff).to receive(:has_encoded_file_paths?).and_return(true)
            expect(subject[:has_encoded_file_paths]).to eq(true)
          end
        end

        context 'when commit is present' do
          let(:commit) { project.repository.commit }
          let(:options) { { commit: commit } }

          it 'calls Commit#has_encoded_file_paths?' do
            expect(commit).to receive(:has_encoded_file_paths?).and_return(true)
            expect(subject[:has_encoded_file_paths]).to eq(true)
          end
        end
      end
    end
  end
end
