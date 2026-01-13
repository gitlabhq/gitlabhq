# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Inputs::ProcessorService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:inputs_spec) do
    {
      'environment' => { 'type' => 'string', 'default' => 'staging', 'options' => %w[staging production] },
      'debug' => { 'type' => 'boolean', 'default' => false }
    }
  end

  let(:job) { create(:ci_build, pipeline: pipeline, options: { inputs: inputs_spec }) }
  let(:inputs) { {} }

  subject(:service) { described_class.new(job, inputs) }

  describe '#execute' do
    context 'when no inputs are provided' do
      let(:inputs) { {} }

      it 'returns success with empty inputs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:inputs]).to eq({})
      end
    end

    context 'when job has no inputs spec' do
      let(:job) { create(:ci_build, pipeline: pipeline) }
      let(:inputs) { { environment: 'production' } }

      it 'returns success with the provided inputs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:inputs]).to eq({ environment: 'production' })
      end
    end

    context 'when valid inputs are provided' do
      let(:inputs) { { environment: 'production', debug: true } }

      it 'returns success with all inputs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:inputs]).to eq({ environment: 'production', debug: true })
      end
    end

    context 'when some inputs match their default values' do
      let(:inputs) { { environment: 'staging', debug: true } }

      it 'only returns inputs that differ from defaults' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:inputs]).to eq({ debug: true })
      end
    end

    context 'when all inputs match their default values' do
      let(:inputs) { { environment: 'staging', debug: false } }

      it 'returns success with empty inputs' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:inputs]).to eq({})
      end
    end

    context 'when inputs are invalid' do
      let(:inputs) { { environment: 'development' } }

      it 'returns a validation error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(
          '`environment` input: `development` cannot be used because it is not in the list of allowed options'
        )
      end
    end

    context 'when unknown inputs are provided' do
      context 'with a single unknown input' do
        let(:inputs) { { environment: 'production', unknown_input: 'value' } }

        it 'returns an error' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Unknown input: unknown_input')
        end
      end

      context 'with multiple unknown inputs' do
        let(:inputs) { { environment: 'production', unknown_one: 'value', unknown_two: 'value' } }

        it 'returns an error listing all unknown inputs' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Unknown inputs: unknown_one, unknown_two')
        end
      end
    end

    context 'when inputs have multiple validation errors' do
      let(:inputs) { { environment: 'development', debug: 'not a boolean' } }

      it 'returns all validation errors' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to include('`environment` input')
        expect(result.message).to include('`debug` input')
      end
    end
  end
end
