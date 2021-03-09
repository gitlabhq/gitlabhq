# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge request content spec' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, :with_head_pipeline, target_project: project, source_project: project) }
  let_it_be(:ci_build) { create(:ci_build, :artifacts, pipeline: merge_request.head_pipeline) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  shared_examples 'cached widget request' do
    it 'avoids N+1 queries when multiple job artifacts are present' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get cached_widget_project_json_merge_request_path(project, merge_request, format: :json)
      end

      create_list(:ci_build, 10, :artifacts, pipeline: merge_request.head_pipeline)

      expect do
        get cached_widget_project_json_merge_request_path(project, merge_request, format: :json)
      end.not_to exceed_query_limit(control)
    end
  end

  describe 'GET cached_widget' do
    it_behaves_like 'cached widget request'

    context 'with non_public_artifacts disabled' do
      before do
        stub_feature_flags(non_public_artifacts: false)
      end

      it_behaves_like 'cached widget request'
    end
  end
end
