# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :yaml_processor_feature_flag_corectness, :aggregate_failures do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service) { described_class.new(project, user, { ref: 'master' }) }
  let(:config) do
    <<-YAML
    stages:
      - build
      - test
      - deploy

    build:
      stage: build
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
  let(:current_partition_id) { 123 }

  before do
    stub_ci_pipeline_yaml_file(config)
    stub_const(
      'Gitlab::Ci::Pipeline::Chain::AssignPartition::DEFAULT_PARTITION_ID',
      current_partition_id)
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
  end

  def find_metadata(name)
    pipeline
      .processables
      .find { |job| job.name == name }
      .metadata
  end
end
