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

    context 'when the :run keyword is used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: true))
      end

      it 'tracks the usage of the :run keyword' do
        expect(step).to receive(:track_internal_event)
          .with('use_run_keyword_in_cicd_yaml', project: project, user: user)

        perform
      end
    end

    context 'when the :run keyword is not used in the pipeline config' do
      before do
        allow(command).to receive(:yaml_processor_result)
          .and_return(instance_double(Gitlab::Ci::YamlProcessor::Result, uses_keyword?: false))
      end

      it 'does not track the usage of the :run keyword' do
        expect(step).not_to receive(:track_internal_event)

        perform
      end
    end
  end

  describe '#break?' do
    subject { step.break? }

    it { is_expected.to be_falsy }
  end
end
