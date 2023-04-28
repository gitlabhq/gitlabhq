# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelinesController, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  before_all do
    create(:ci_build, pipeline: pipeline, stage: 'build')
    create(:ci_bridge, pipeline: pipeline, stage: 'build')
    create(:generic_commit_status, pipeline: pipeline, stage: 'build')

    project.add_developer(user)
  end

  before do
    login_as(user)
  end

  describe "GET index.json" do
    it 'does not execute N+1 queries' do
      get_pipelines_index

      create_pipelines

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get_pipelines_index
      end.count

      create_pipelines

      # There appears to be one extra query for Pipelines#has_warnings? for some reason
      expect { get_pipelines_index }.not_to exceed_all_query_limit(control_count + 1)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['pipelines'].count).to eq(11)
    end

    def create_pipelines
      %w[pending running success failed canceled].each do |status|
        pipeline = create(:ci_pipeline, project: project, status: status)
        create(:ci_build, :failed, pipeline: pipeline)
      end
    end

    def get_pipelines_index
      get namespace_project_pipelines_path(
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        format: :json)
    end
  end

  describe "GET stages.json" do
    it 'does not execute N+1 queries' do
      request_build_stage

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        request_build_stage
      end.count

      create(:ci_build, pipeline: pipeline, stage: 'build')

      2.times do |i|
        create(:ci_build,
          name: "test retryable #{i}",
          pipeline: pipeline,
          stage: 'build',
          status: :failed)
      end

      expect { request_build_stage }.not_to exceed_all_query_limit(control_count)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with retried builds' do
      it 'does not execute N+1 queries' do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')

        request_build_stage(retried: true)

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          request_build_stage(retried: true)
        end.count

        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')
        create(:ci_build, :failed, pipeline: pipeline, stage: 'build')

        expect { request_build_stage(retried: true) }.not_to exceed_all_query_limit(control_count)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    def request_build_stage(params = {})
      get stage_namespace_project_pipeline_path(
        params.merge(
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: pipeline.id,
          stage: 'build',
          format: :json
        )
      )
    end
  end
end
