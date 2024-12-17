# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :aggregate_failures,
  feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service) { described_class.new(project, user, { ref: 'master' }) }
  let(:config) do
    <<-YAML
    stages:
      - build
      - test
      - deploy

    needs:build:
      stage: build
      script: echo "needs..."

    build:
      stage: build
      needs: ["needs:build"]
      script: make build

    test:
      stage: test
      trigger:
        include: child.yml

    deploy:
      stage: deploy
      script: make deploy
      environment: review/$CI_JOB_NAME
    YAML
  end

  let(:pipeline) { service.execute(:push).payload }
  let(:current_partition_id) { ci_testing_partition_id }

  before do
    stub_ci_pipeline_yaml_file(config)
    allow(Ci::Pipeline).to receive(:current_partition_value) { current_partition_id }
    project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
  end

  it 'assigns partition_id to pipeline' do
    expect(pipeline).to be_created_successfully
    expect(pipeline.partition_id).to eq(current_partition_id)
  end

  it 'assigns partition_id to stages' do
    stage_partition_ids = pipeline.stages.map(&:partition_id).uniq

    expect(stage_partition_ids).to eq([current_partition_id])
  end

  it 'assigns partition_id to processables' do
    processables_partition_ids = pipeline.processables.map(&:partition_id).uniq

    expect(processables_partition_ids).to eq([current_partition_id])
  end

  it 'assigns partition_id to metadata' do
    metadata_partition_ids = pipeline.processables.map { |job| job.metadata.partition_id }.uniq

    expect(metadata_partition_ids).to eq([current_partition_id])
  end

  it 'correctly assigns partition and environment' do
    metadata = find_metadata('deploy')

    expect(metadata.partition_id).to eq(current_partition_id)
    expect(metadata.expanded_environment_name).to eq('review/deploy')
  end

  context 'with pipeline variables' do
    let(:variables_attributes) do
      [
        { key: 'SOME_VARIABLE', secret_value: 'SOME_VAL' },
        { key: 'OTHER_VARIABLE', secret_value: 'OTHER_VAL' }
      ]
    end

    let(:service) do
      described_class.new(
        project,
        user,
        { ref: 'master', variables_attributes: variables_attributes })
    end

    it 'assigns partition_id to pipeline' do
      expect(pipeline).to be_created_successfully
      expect(pipeline.partition_id).to eq(current_partition_id)
    end

    it 'assigns partition_id to variables' do
      variables_partition_ids = pipeline.variables.map(&:partition_id).uniq

      expect(pipeline.variables.size).to eq(2)
      expect(variables_partition_ids).to eq([current_partition_id])
    end

    it 'assigns partition_id to needs' do
      needs = find_need('build')

      expect(needs.partition_id).to eq(current_partition_id)
    end
  end

  context 'with parent child pipelines' do
    before do
      allow(Ci::Pipeline)
        .to receive(:current_partition_value)
        .and_return(current_partition_id, 301, 302)

      allow_next_found_instance_of(Ci::Bridge) do |bridge|
        allow(bridge).to receive(:yaml_for_downstream).and_return(child_config)
      end
    end

    let(:config) do
      <<-YAML
      test:
        trigger:
          include: child.yml
      YAML
    end

    let(:child_config) do
      <<-YAML
      test:
        script: make test
      YAML
    end

    it 'assigns partition values to child pipelines', :aggregate_failures, :sidekiq_inline do
      expect(pipeline).to be_created_successfully
      expect(pipeline.child_pipelines).to all be_created_successfully

      child_partition_ids = pipeline.child_pipelines.map(&:partition_id).uniq
      child_jobs = CommitStatus.where(commit_id: pipeline.child_pipelines)

      expect(pipeline.partition_id).to eq(current_partition_id)
      expect(child_partition_ids).to eq([current_partition_id])

      expect(child_jobs).to all be_a(Ci::Build)
      expect(child_jobs.pluck(:partition_id).uniq).to eq([current_partition_id])
    end
  end

  def find_metadata(name)
    pipeline
      .processables
      .find { |job| job.name == name }
      .metadata
  end

  def find_need(name)
    pipeline
      .processables
      .find { |job| job.name == name }
      .needs
      .first
  end
end
