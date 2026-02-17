# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobRequest::Response, feature_category: :continuous_integration do
  let(:runner) { build(:ci_runner) }
  let(:job) do
    build(
      :ci_build, runner: runner,
      options: { inputs: { test_input: { type: 'string', default: 'test' } } }
    )
  end

  let(:presented_job) { Ci::BuildRunnerPresenter.new(job) }

  subject(:runner_payload) { described_class.new(presented_job).as_json }

  it 'includes the job inputs' do
    expect(runner_payload[:inputs]).to contain_exactly(
      { key: :test_input, value: { type: 'string', content: 'test' } }
    )
  end

  describe '#steps' do
    subject(:steps) { runner_payload[:steps][0][:script] }

    let(:script) { 'echo one liner' }
    let(:job) { build(:ci_build, runner: runner, options: { script: script }) }

    it 'returns the script' do
      expect(steps).to eq([script])
    end

    context 'with array script' do
      let(:script) { ['echo first', 'echo second'] }

      it 'returns the script' do
        expect(steps).to eq(script)
      end
    end
  end

  describe '#run' do
    let(:job) do
      build(:ci_build, runner: runner, job_definition: job_definition, execution_config: job_execution_config)
    end

    let(:job_definition) { build(:ci_job_definition, config: { run_steps: job_definition_run_steps }) }
    let(:job_definition_run_steps) { [{ name: 'hello_steps' }, { name: 'bye_steps' }] }
    let(:job_execution_config) { build(:ci_builds_execution_configs, run_steps: job_execution_config_run_steps) }
    let(:job_execution_config_run_steps) { [{ 'name' => 'first execution' }, { 'name' => 'last execution' }] }

    it 'returns run_steps from job definition' do
      expect(runner_payload[:run]).to eq(job_definition_run_steps.to_json)
    end

    context 'when feature flag read_from_ci_job_definition_run_steps is disabled' do
      before do
        stub_feature_flags(read_from_ci_job_definition_run_steps: false)
      end

      it 'returns run_steps from execution config' do
        expect(runner_payload[:run]).to eq(job_execution_config_run_steps.to_json)
      end
    end
  end
end
