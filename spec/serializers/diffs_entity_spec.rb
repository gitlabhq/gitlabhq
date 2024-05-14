# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffsEntity, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  let(:request) { EntityRequest.new(project: project, current_user: user) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:options) do
    {
      request: request,
      merge_request: merge_request,
      merge_request_diffs: merge_request_diffs
    }
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

    context 'broken merge request' do
      let(:merge_request) { create(:merge_request, :invalid, target_project: project, source_project: project) }

      it 'renders without errors' do
        expect { subject }.not_to raise_error
      end
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

    describe 'diff_files' do
      let(:diff_files) { merge_request_diffs.first.diffs.diff_files }

      it 'serializes diff files using DiffFileEntity' do
        expect(DiffFileEntity)
          .to receive(:represent)
          .with(
            diff_files,
            hash_including(options.merge(conflicts: nil))
          )

        subject[:diff_files]
      end

      context 'when there are conflicts' do
        before do
          allow(entity).to receive(:conflicts_with_types).and_return({
            diff_files.first.new_path => {
              conflict_type: :both_modified,
              conflict_type_when_renamed: :both_modified
            }
          })
        end

        it 'serializes diff files with conflicts' do
          expect(DiffFileEntity)
            .to receive(:represent)
            .with(
              diff_files,
              hash_including(options.merge(conflicts: entity.conflicts_with_types))
            )

          subject[:diff_files]
        end
      end
    end
  end
end
