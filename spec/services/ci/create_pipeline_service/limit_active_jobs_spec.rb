# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:existing_pipeline) { create(:ci_pipeline, project: project) }

  let(:service) { described_class.new(project, user, ref: 'refs/heads/master') }

  subject(:pipeline) { service.execute(:push).payload }

  before do
    create_list(:ci_build, 8, pipeline: existing_pipeline)
    create_list(:ci_bridge, 1, pipeline: existing_pipeline)

    stub_ci_pipeline_yaml_file(<<~YAML)
    job1:
      script: echo
    job3:
      trigger:
        project: org/my-project
    job4:
      script: echo
      only: [tags]
    YAML
  end

  context 'when project has exceeded the active jobs limit' do
    before do
      project.namespace.actual_limits.update!(ci_active_jobs: 10)
    end

    it 'fails the pipeline before populating it' do
      expect(pipeline).to be_failed
      expect(pipeline).to be_job_activity_limit_exceeded

      expect(pipeline.errors.full_messages)
        .to include("Project exceeded the allowed number of jobs in active pipelines. Retry later.")
      expect(pipeline.statuses).to be_empty
    end
  end

  context 'when project has not exceeded the active jobs limit' do
    before do
      project.namespace.actual_limits.update!(ci_active_jobs: 20)
    end

    it 'creates the pipeline successfully' do
      expect(pipeline).to be_created
    end
  end
end
