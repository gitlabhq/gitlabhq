# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, '#execute',
  feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }

  let(:upstream_project) { create(:project, :repository, group: group) }
  let(:downstream_project) { create(:project, :repository, group: group) }
  let(:user) { create(:user) }

  let(:service) do
    described_class.new(upstream_project, user, ref: 'master')
  end

  before do
    upstream_project.add_developer(user)
    downstream_project.add_developer(user)
    create_gitlab_ci_yml(upstream_project, upstream_config)
    create_gitlab_ci_yml(downstream_project, downstream_config)
  end

  it_behaves_like 'creating a pipeline with environment keyword' do
    let(:execute_service) { service.execute(:push) }
    let(:upstream_config) { config }
    let(:expected_deployable_class) { Ci::Bridge }
    let(:expected_deployment_status) { 'running' }
    let(:expected_job_status) { 'running' }
    let(:downstream_config) { YAML.dump({ deploy: { script: 'deploy' } }) }
    let(:base_config) do
      {
        trigger: {
          project: downstream_project.full_path,
          strategy: 'depend'
        }
      }
    end
  end

  context 'with resource group', :aggregate_failures do
    let(:upstream_config) do
      <<~YAML
      instrumentation_test:
        stage: test
        resource_group: iOS
        trigger:
          project: #{downstream_project.full_path}
          strategy: depend
      YAML
    end

    let(:downstream_config) do
      <<~YAML
      test:
        script: echo "Testing..."
      YAML
    end

    it 'creates bridge job with resource group' do
      pipeline = create_pipeline!
      Ci::InitialPipelineProcessWorker.new.perform(pipeline.id)

      test = pipeline.statuses.find_by(name: 'instrumentation_test')
      expect(pipeline).to be_created_successfully
      expect(pipeline.triggered_pipelines).not_to be_exist
      expect(upstream_project.resource_groups.count).to eq(1)
      expect(test).to be_a Ci::Bridge
      expect(test).to be_waiting_for_resource
      expect(test.resource_group.key).to eq('iOS')
    end

    context 'when sidekiq processes the job', :sidekiq_inline do
      it 'transitions to pending status and triggers a downstream pipeline' do
        pipeline = create_pipeline!

        test = pipeline.statuses.find_by(name: 'instrumentation_test')
        expect(test).to be_running
        expect(pipeline.triggered_pipelines.count).to eq(1)
      end

      context 'when the resource is occupied by the other bridge' do
        before do
          resource_group = create(:ci_resource_group, project: upstream_project, key: 'iOS')
          resource_group.assign_resource_to(create(:ci_build, project: upstream_project))
        end

        it 'stays waiting for resource' do
          pipeline = create_pipeline!

          test = pipeline.statuses.find_by(name: 'instrumentation_test')
          expect(test).to be_waiting_for_resource
          expect(pipeline.triggered_pipelines.count).to eq(0)
        end
      end
    end
  end

  def create_pipeline!
    service.execute(:push).payload
  end

  def create_gitlab_ci_yml(project, content)
    project.repository.create_file(user, '.gitlab-ci.yml', content, branch_name: 'master', message: 'test')
  end
end
