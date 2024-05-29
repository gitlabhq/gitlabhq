# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Diffs stream', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

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

    let_it_be(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    context 'when offset is not given' do
      it 'streams all diffs' do
        go

        file_paths = merge_request.diffs.diff_files.to_a.map(&:file_path)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include(*file_paths)
      end
    end

    context 'when offset is given' do
      let(:offset) { 5 }

      it 'streams diffs except the offset' do
        go(offset: offset)

        diff_files = merge_request.diffs.diff_files.to_a
        offset_file_paths = diff_files.take(offset).map(&:file_path)
        remaining_file_paths = diff_files.slice(offset..).map(&:file_path)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).not_to include(*offset_file_paths)
        expect(response.body).to include(*remaining_file_paths)
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
  end
end
