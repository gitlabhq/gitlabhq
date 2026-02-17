# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::KeywordUsage, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user) }
  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject(:perform) { step.perform! }

    context 'when the keyword of interest is used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: true,
            uses_nested_keyword?: false, uses_inputs?: false, uses_input_rules?: false))
      end

      it 'tracks the usage of the keyword of interest' do
        expect(step).to receive(:track_internal_event)
          .with(a_string_matching(/\Ause_\w+_keyword_in_cicd_yaml\z/), project: project, user: user)
          .exactly(4).times

        perform
      end
    end

    context 'when the keyword of interest is not used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: false,
            uses_nested_keyword?: false, uses_inputs?: false, uses_input_rules?: false))
      end

      it 'does not track the usage of the keyword of interest' do
        expect(step).not_to receive(:track_internal_event)

        perform
      end
    end

    context 'when inputs keyword is used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: false,
            uses_nested_keyword?: false, uses_inputs?: true, uses_input_rules?: false))
      end

      it 'tracks the usage of the inputs keyword' do
        expect { perform }.to trigger_internal_events('use_inputs_keyword_in_cicd_yaml')
          .with(project: project, user: user)
      end
    end

    context 'when input_rules keyword is used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: false,
            uses_nested_keyword?: false, uses_inputs?: false, uses_input_rules?: true))
      end

      it 'tracks the usage of the input_rules keyword' do
        expect { perform }.to trigger_internal_events('use_input_rules_keyword_in_cicd_yaml')
          .with(project: project, user: user)
      end
    end
  end

  describe '#break?' do
    subject { step.break? }

    it { is_expected.to be_falsy }
  end
end
