# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Metrics, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', user: user) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master')
  end

  let(:step) { described_class.new(pipeline, command) }

  subject(:run_chain) { step.perform! }

  it 'does not break the chain' do
    run_chain

    expect(step.break?).to be false
  end

  it 'enqueues PipelineCreationMetricsWorker with basic params' do
    expect(::Ci::PipelineCreationMetricsWorker)
      .to receive(:perform_async)
      .with(pipeline.id, nil, nil, nil)

    run_chain
  end

  context 'when pipeline has inputs' do
    let(:inputs) { { deploy_strategy: 'manual', job_stage: 'deploy' } }

    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        origin_ref: 'master',
        inputs: inputs
      )
    end

    before do
      allow(command).to receive(:yaml_processor_result).and_return(nil)
    end

    it 'enqueues worker with inputs_count' do
      expect(::Ci::PipelineCreationMetricsWorker)
        .to receive(:perform_async)
        .with(pipeline.id, 2, nil, nil)

      run_chain
    end
  end

  context 'when pipeline has templates' do
    let(:yaml_processor_result) { instance_double(Gitlab::Ci::YamlProcessor::Result) }
    let(:template_names) { ['Auto-DevOps.gitlab-ci.yml', 'Security/SAST.gitlab-ci.yml'] }

    before do
      allow(command).to receive(:yaml_processor_result).and_return(yaml_processor_result)
      allow(yaml_processor_result).to receive_messages(
        included_templates: template_names,
        uses_keyword?: false,
        uses_nested_keyword?: false,
        uses_inputs?: false,
        uses_input_rules?: false
      )
    end

    it 'enqueues worker with template_names' do
      expect(::Ci::PipelineCreationMetricsWorker)
        .to receive(:perform_async)
        .with(
          pipeline.id,
          nil,
          template_names,
          {
            run: false,
            only: false,
            except: false,
            artifacts_reports_junit: false,
            job_inputs: false,
            inputs: false,
            input_rules: false
          }
        )

      run_chain
    end
  end

  context 'when pipeline uses keywords' do
    let(:yaml_processor_result) { instance_double(Gitlab::Ci::YamlProcessor::Result) }

    before do
      allow(command).to receive(:yaml_processor_result).and_return(yaml_processor_result)
      allow(yaml_processor_result).to receive_messages(
        included_templates: nil,
        uses_keyword?: false,
        uses_nested_keyword?: false,
        uses_inputs?: false,
        uses_input_rules?: false
      )
      allow(yaml_processor_result).to receive(:uses_keyword?).with(:run).and_return(true)
      allow(yaml_processor_result).to receive(:uses_keyword?).with(:only).and_return(false)
      allow(yaml_processor_result).to receive(:uses_keyword?).with(:except).and_return(true)
      allow(yaml_processor_result).to receive(:uses_keyword?).with(:inputs).and_return(false)
      allow(yaml_processor_result).to receive(:uses_nested_keyword?).with(%i[artifacts reports junit]).and_return(false)
    end

    it 'enqueues worker with keyword_usage' do
      expect(::Ci::PipelineCreationMetricsWorker)
        .to receive(:perform_async)
        .with(
          pipeline.id,
          nil,
          nil,
          {
            run: true,
            only: false,
            except: true,
            artifacts_reports_junit: false,
            job_inputs: false,
            inputs: false,
            input_rules: false
          }
        )

      run_chain
    end
  end
end
