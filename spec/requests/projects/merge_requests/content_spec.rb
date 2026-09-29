# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge request content spec', feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: user) }
  let_it_be(:merge_request) { create(:merge_request, :with_head_pipeline, target_project: project, source_project: project) }
  let_it_be(:ci_build) { create(:ci_build, :artifacts, pipeline: merge_request.head_pipeline) }

  before do
    sign_in(user)
  end

  shared_examples 'cached widget request' do
    it 'avoids N+1 queries when multiple job artifacts are present' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get cached_widget_project_json_merge_request_path(project, merge_request, format: :json)
      end

      create_list(:ci_build, 3, :artifacts, pipeline: merge_request.head_pipeline)

      expect do
        get cached_widget_project_json_merge_request_path(project, merge_request, format: :json)
      end.not_to exceed_query_limit(control).allow_skip_cache_inconsistency
    end
  end

  describe 'GET cached_widget' do
    it_behaves_like 'cached widget request'
  end

  describe 'GET widget' do
    subject(:get_widget) { get widget_project_json_merge_request_path(project, merge_request, format: :json) }

    before do
      MergeRequest.id_in(merge_request.id).update_all(merge_status: 'unchecked')
    end

    it 'enqueues the mergeability check without writing the merge status' do
      expect(MergeRequestMergeabilityCheckWorker).to receive(:perform_async).with(merge_request.id).at_least(:once)

      get_widget

      expect(response).to have_gitlab_http_status(:ok)
      expect(MergeRequest.find(merge_request.id)).to be_unchecked
    end

    context 'when the enqueue_widget_mergeability_check feature flag is disabled' do
      before do
        stub_feature_flags(enqueue_widget_mergeability_check: false)
      end

      it 'checks mergeability during the request' do
        get_widget

        expect(response).to have_gitlab_http_status(:ok)
        expect(MergeRequest.find(merge_request.id)).to be_can_be_merged
      end
    end
  end
end
