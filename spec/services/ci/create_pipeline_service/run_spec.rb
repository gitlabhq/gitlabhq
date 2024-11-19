# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService,
  feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { project.first_owner }

  let(:service)  { described_class.new(project, user, { ref: 'master' }) }
  let(:pipeline) { service.execute(:push).payload }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  context 'when job has valid run configuration' do
    let(:config) do
      <<-CI_CONFIG
      job:
        run:
          - name: step1
            script: echo 'hello step1'
          - name: step2
            step: some_predefined_step
            env:
              VAR1: 'value1'
            inputs:
              input1: 'value1'
      CI_CONFIG
    end

    it 'creates a job with run data' do
      expect(pipeline).to be_created_successfully

      job = pipeline.builds.first
      expect(job.execution_config.run_steps).to eq([
        {
          'name' => 'step1',
          'script' => "echo 'hello step1'"
        },
        {
          'name' => 'step2',
          'step' => 'some_predefined_step',
          'env' => { 'VAR1' => 'value1' },
          'inputs' => { 'input1' => 'value1' }
        }
      ])
    end
  end

  context 'when job has multiple run steps with different configurations' do
    let(:config) do
      <<-CI_CONFIG
      job1:
        run:
          - name: script_step
            script: echo 'hello script'
          - name: predefined_step
            step: some_step
            env:
              DEBUG: 'true'

      job2:
        run:
          - name: complex_script
            script: |
              echo 'multi-line'
              echo 'script'
          - name: step_with_inputs
            step: another_step
            inputs:
              param1: value1
              param2: value2
      CI_CONFIG
    end

    it 'creates jobs with correct execution_config data' do
      expect(pipeline).to be_created_successfully

      job1 = pipeline.builds.find_by(name: 'job1')
      expect(job1.execution_config.run_steps).to eq([
        {
          'name' => 'script_step',
          'script' => "echo 'hello script'"
        },
        {
          'name' => 'predefined_step',
          'step' => 'some_step',
          'env' => { 'DEBUG' => 'true' }
        }
      ])

      job2 = pipeline.builds.find_by(name: 'job2')
      expect(job2.execution_config.run_steps).to eq([
        {
          'name' => 'complex_script',
          'script' => "echo 'multi-line'\necho 'script'\n"
        },
        {
          'name' => 'step_with_inputs',
          'step' => 'another_step',
          'inputs' => {
            'param1' => 'value1',
            'param2' => 'value2'
          }
        }
      ])
    end
  end

  context 'when job has invalid run configuration' do
    let(:config) do
      <<-CI_CONFIG
      job:
        run:
          - script: echo 'missing name'
          - name: invalid_step
            step: 123
          - name: invalid_env
            script: echo 'test'
            env:
              KEY: null
      CI_CONFIG
    end

    it 'returns errors for invalid configuration' do
      expect(pipeline).not_to be_created_successfully
      expect(pipeline.errors.full_messages).to include(
        "jobs:job run object property at `/0/script` is a disallowed additional property"
      )
    end
  end

  context 'when multiple jobs have the same run configuration' do
    let(:config) do
      <<-CI_CONFIG
      job1:
        run:
          - name: step1
            script: echo 'hello step1'
          - name: step2
            step: some_predefined_step
            env:
              VAR1: 'value1'
            inputs:
              input1: 'value1'
      job2:
        run:
          - name: step1
            script: echo 'hello step1'
          - name: step2
            step: some_predefined_step
            env:
              VAR1: 'value1'
            inputs:
              input1: 'value1'
      job3:
        run:
          - name: step1
            script: echo 'hello step1 from job 3'
      CI_CONFIG
    end

    it 'creates one execution config for each unique execution config' do
      expect(pipeline).to be_created_successfully

      job1 = pipeline.builds.find_by(name: 'job1')
      job2 = pipeline.builds.find_by(name: 'job2')
      job3 = pipeline.builds.find_by(name: 'job3')

      expect(Ci::BuildExecutionConfig.count).to eq(2)
      expect(job1.execution_config).to eq(job2.execution_config)
      expect(job1.execution_config.builds).to contain_exactly(job1, job2)
      expect(job3.execution_config.builds).to contain_exactly(job3)
    end
  end
end
