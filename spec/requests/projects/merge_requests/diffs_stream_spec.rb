# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Diffs stream', feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:diff_options_hash) do
    {
      ignore_whitespace_change: false,
      expanded: false,
      use_extra_viewer_as_main: true,
      offset_index: 0,
      only_context_commits: false
    }
  end

  before do
    sign_in(user)
  end

  describe 'GET diffs_stream' do
    def go(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }

      get diffs_stream_namespace_project_merge_request_path(params.merge(extra_params))
    end

    let_it_be_with_reload(:merge_request) do
      create(
        :merge_request_with_diffs,
        source_branch: 'expand-collapse-files',
        target_branch: 'master',
        target_project: project,
        source_project: project
      )
    end

    let_it_be(:base_diff_1) { merge_request.merge_request_diff }

    let_it_be(:commit_id) do
      create_file_in_repo(
        merge_request.project,
        'expand-collapse-files',
        'expand-collapse-files',
        'new_file.txt',
        'new content'
      )[:result]
    end

    let_it_be(:base_diff_2) do
      merge_request.clear_memoized_shas
      merge_request.create_merge_request_diff
    end

    let(:diff_files) { merge_request.merge_request_diff.diffs.diff_files }

    context 'when accessed' do
      it 'passes hash of options to #diffs_for_streaming' do
        expect_next_instance_of(::Projects::MergeRequests::DiffsStreamController) do |controller|
          context = controller.view_context
          allow(controller).to receive(:view_context).and_return(context)
          expect(controller).to receive(:stream_diff_files)
            .with(diff_options_hash, context)
            .and_call_original
        end

        go
      end

      it 'renders merge request diff file component' do
        expect_any_instance_of(::RapidDiffs::MergeRequestDiffFileComponent) do |component|
          expect(component).to receive(:render_in).and_call_original
        end

        go
      end

      context 'when rapid_diffs_on_mr_show feature flag is disabled' do
        before do
          stub_feature_flags(rapid_diffs_on_mr_show: false)
        end

        it 'does not include only_context_commits in options' do
          expected_options = diff_options_hash.except(:only_context_commits)

          expect_next_instance_of(::Projects::MergeRequests::DiffsStreamController) do |controller|
            context = controller.view_context
            allow(controller).to receive(:view_context).and_return(context)
            expect(controller).to receive(:stream_diff_files)
              .with(expected_options, context)
              .and_call_original
          end

          go
        end
      end
    end

    context 'when offset is not given' do
      it 'streams all diffs' do
        go

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include(*file_identifier_hashes(merge_request.merge_request_diff))
      end

      context 'when HEAD diff is present' do
        before do
          merge_request.reset.create_merge_head_diff!
        end

        it 'streams all diffs' do
          go

          expect(response).to have_gitlab_http_status(:success)
          expect(response.body).to include(*file_identifier_hashes(merge_request.merge_head_diff))
        end
      end

      context 'when diff_id param is set' do
        it 'streams all diffs in the specified diff' do
          go(diff_id: base_diff_2.id)

          expect(response).to have_gitlab_http_status(:success)
          expect(response.body.scan('<diff-file ').size).to eq(base_diff_2.files_count)
          expect(response.body).to include(*file_identifier_hashes(base_diff_2))
        end

        context 'when start_sha param is set' do
          let(:compare) do
            ::MergeRequests::MergeRequestDiffComparison
              .new(base_diff_2)
              .compare_with(base_diff_1.head_commit_sha)
          end

          it 'streams all diffs between diff versions' do
            go(diff_id: base_diff_2.id, start_sha: base_diff_1.head_commit_sha)

            expect(response).to have_gitlab_http_status(:success)
            expect(response.body.scan('<diff-file ').size).to eq(1)
            expect(response.body).to include(*file_identifier_hashes(compare))
          end
        end
      end

      context 'when commit_id param is set' do
        it 'streams all diffs in the specified diff' do
          go(commit_id: commit_id)

          expect(response).to have_gitlab_http_status(:success)
          expect(response.body.scan('<diff-file ').size).to eq(1)
          expect(response.body).to include(*file_identifier_hashes(project.commit(commit_id)))
        end
      end
    end

    context 'when offset is given' do
      let(:offset) { 5 }

      it 'streams diffs except the offset' do
        go(offset: offset)

        offset_file_identifier_hashes = diff_files.to_a.take(offset).map(&:file_hash)
        remaining_file_identifier_hashes = diff_files.to_a.slice(offset..).map(&:file_hash)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).not_to include(*offset_file_identifier_hashes)
        expect(response.body).to include(*remaining_file_identifier_hashes)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(::RapidDiffs::DiffFileComponent)
          .to receive(:new).and_raise(StandardError.new('something went wrong'))
      end

      it 'prints out error message' do
        go

        expect(response.body).to include('something went wrong')
      end
    end

    include_examples 'with diffs_blobs param'

    context 'when only_context_commits is true' do
      let_it_be(:sha1) { "33f3729a45c02fc67d00adb1b8bca394b0e761d9" }
      let_it_be(:sha2) { "ae73cb07c9eeaf35924a10f713b364d32b2dd34f" }

      before_all do
        create(:merge_request_context_commit, merge_request: merge_request, sha: sha1,
          committed_date: project.commit_by(oid: sha1).committed_date)
        create(:merge_request_context_commit, merge_request: merge_request, sha: sha2,
          committed_date: project.commit_by(oid: sha2).committed_date)
      end

      it 'streams context commit diffs' do
        go(only_context_commits: true)

        expect(response).to have_gitlab_http_status(:success)

        context_diff_files = merge_request.context_commits_diff.diffs.diff_files
        context_file_hashes = context_diff_files.to_a.map(&:file_hash)

        expect(response.body).to include(*context_file_hashes)
      end

      it 'passes only_context_commits option to stream_diff_files' do
        expected_options = diff_options_hash.merge(only_context_commits: true)

        expect_next_instance_of(::Projects::MergeRequests::DiffsStreamController) do |controller|
          context = controller.view_context
          allow(controller).to receive(:view_context).and_return(context)
          expect(controller).to receive(:stream_diff_files)
            .with(expected_options, context)
            .and_call_original
        end

        go(only_context_commits: true)
      end
    end
  end
end
