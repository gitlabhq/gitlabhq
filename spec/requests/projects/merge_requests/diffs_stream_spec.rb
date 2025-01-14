# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Diffs stream', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:diff_options_hash) do
    {
      ignore_whitespace_change: false,
      expanded: false,
      use_extra_viewer_as_main: true,
      offset_index: 0
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

    let(:diff_files) { merge_request.merge_request_diff.diffs.diff_files }

    context 'when accessed' do
      it 'passes hash of options to #diffs_for_streaming' do
        expect_next_instance_of(::Projects::MergeRequests::DiffsStreamController) do |controller|
          expect(controller).to receive(:stream_diff_files)
            .with(diff_options_hash)
            .and_call_original
        end

        go
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
    end

    context 'when offset is given' do
      let(:offset) { 5 }

      it 'streams diffs except the offset' do
        go(offset: offset)

        offset_file_identifier_hashes = diff_files.to_a.take(offset).map(&:file_identifier_hash)
        remaining_file_identifier_hashes = diff_files.to_a.slice(offset..).map(&:file_identifier_hash)

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

    context 'when rapid_diffs FF is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns 404' do
        go

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    include_examples 'with diffs_blobs param'
  end
end
