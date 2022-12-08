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

  describe "GET stages.json" do
    it 'does not execute N+1 queries' do
      request_build_stage

      control_count = ActiveRecord::QueryRecorder.new do
        request_build_stage
      end.count

      create(:ci_build, pipeline: pipeline, stage: 'build')

      expect { request_build_stage }.not_to exceed_query_limit(control_count)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with retried builds' do
      it 'does not execute N+1 queries' do
        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')

        request_build_stage(retried: true)

        control_count = ActiveRecord::QueryRecorder.new do
          request_build_stage(retried: true)
        end.count

        create(:ci_build, :retried, :failed, pipeline: pipeline, stage: 'build')

        expect { request_build_stage(retried: true) }.not_to exceed_query_limit(control_count)

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
