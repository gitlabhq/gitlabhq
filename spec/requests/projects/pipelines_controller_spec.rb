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

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get_pipelines_index
      end

      create_pipelines

      # There appears to be one extra query for Pipelines#has_warnings? for some reason
      expect { get_pipelines_index }.not_to exceed_all_query_limit(control).with_threshold(1)
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

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        request_build_stage
      end

      create(:ci_build, pipeline: pipeline, stage: 'build')

      2.times do |i|
        create(:ci_build,
          name: "test retryable #{i}",
          pipeline: pipeline,
          stage: 'build',
          status: :failed)
      end

      expect { request_build_stage }.not_to exceed_all_query_limit(control)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when pipeline_stage_set_last_modified is disabled' do
      before do
        stub_feature_flags(pipeline_stage_set_last_modified: false)
      end

      it 'does not set Last-Modified' do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')

        request_build_stage

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Last-Modified']).to be_nil
        expect(response.headers['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      end
    end

    context 'when pipeline_stage_set_last_modified is enabled' do
      before do
        stub_feature_flags(pipeline_stage_set_last_modified: true)
        stage.statuses.update_all(updated_at: status_timestamp)
      end

      let(:last_modified) { DateTime.parse(response.headers['Last-Modified']).utc }
      let(:cache_control) { response.headers['Cache-Control'] }
      let(:expected_cache_control) { 'max-age=0, private, must-revalidate' }

      context 'when status.updated_at is before stage.updated' do
        let(:stage) { pipeline.stage('build') }
        let(:status_timestamp) { stage.updated_at - 10.minutes }

        it 'sets correct Last-Modified of stage.updated_at' do
          request_build_stage

          expect(response).to have_gitlab_http_status(:ok)
          expect(last_modified).to be_within(1.second).of stage.updated_at
          expect(cache_control).to eq(expected_cache_control)
        end
      end

      context 'when status.updated_at is after stage.updated' do
        let(:stage) { pipeline.stage('build') }
        let(:status_timestamp) { stage.updated_at + 10.minutes }

        it 'sets correct Last-Modified of max(status.updated_at)' do
          request_build_stage

          expect(response).to have_gitlab_http_status(:ok)
          expect(last_modified).to be_within(1.second).of status_timestamp
          expect(cache_control).to eq(expected_cache_control)
        end
      end
    end

    context 'with retried builds' do
      it 'does not execute N+1 queries' do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')

        request_build_stage(retried: true)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          request_build_stage(retried: true)
        end

        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')
        create(:ci_build, :failed, pipeline: pipeline, stage: 'build')

        expect { request_build_stage(retried: true) }.not_to exceed_all_query_limit(control)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns retried builds in the correct order' do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build', name: 'retried_job_1')
        create(:ci_build, :retried, :success, pipeline: pipeline, stage: 'build', name: 'retried_job_2')
        create(:ci_build, :retried, :running, pipeline: pipeline, stage: 'build', name: 'retried_job_3')
        create(:ci_build, :retried, :canceled, pipeline: pipeline, stage: 'build', name: 'retried_job_4')
        create(:ci_build, :retried, :pending, pipeline: pipeline, stage: 'build', name: 'retried_job_5')

        request_build_stage(retried: true)

        expect(response).to have_gitlab_http_status(:ok)

        retried_jobs = json_response['retried']
        job_names = retried_jobs.pluck('name')
        expected_order = %w[retried_job_1 retried_job_5 retried_job_3 retried_job_4 retried_job_2]

        expect(job_names).to eq(expected_order)
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
