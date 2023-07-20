# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Yaml::Loader, feature_category: :pipeline_composition do
  describe '#load' do
    let_it_be(:project) { create(:project) }

    let(:inputs) { { test_input: 'hello test' } }

    let(:yaml) do
      <<~YAML
      ---
      spec:
        inputs:
          test_input:
      ---
      test_job:
        script:
          - echo "$[[ inputs.test_input ]]"
      YAML
    end

    subject(:result) { described_class.new(yaml, inputs: inputs).load }

    it 'loads and interpolates CI config YAML' do
      expected_config = { test_job: { script: ['echo "hello test"'] } }

      expect(result).to be_valid
      expect(result).to be_interpolated
      expect(result.content).to eq(expected_config)
    end

    it 'allows the use of YAML reference tags' do
      expect(Psych).to receive(:add_tag).once.with(
        ::Gitlab::Ci::Config::Yaml::Tags::Reference.tag,
        ::Gitlab::Ci::Config::Yaml::Tags::Reference
      )

      result
    end

    context 'when there is an error loading the YAML' do
      let(:yaml) { 'invalid...yaml' }

      it 'returns an error result' do
        expect(result).not_to be_valid
        expect(result.error).to eq('Invalid configuration format')
      end
    end

    context 'when there is an error interpolating the YAML' do
      let(:inputs) { {} }

      it 'returns an error result' do
        expect(result).not_to be_valid
        expect(result.error).to eq('`test_input` input: required value has not been provided')
      end
    end
  end
end
