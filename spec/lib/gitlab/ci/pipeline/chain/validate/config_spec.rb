# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::Config, feature_category: :pipeline_composition do
  let(:project) { create(:project) }
  let(:pipeline) { build_stubbed(:ci_pipeline, project: project, source: :push) }
  let(:inputs) { {} }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, inputs: inputs)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'when params contain more inputs than the inputs limit (20)' do
      let(:inputs) do
        {
          'string' => 'bar',
          boolean: true
        }
      end

      before do
        stub_const("#{described_class}::INPUTS_LIMIT", 1)
      end

      it 'raises an error' do
        step.perform!

        expect(pipeline.errors.full_messages).to include('There cannot be more than 1 inputs')
      end
    end
  end
end
