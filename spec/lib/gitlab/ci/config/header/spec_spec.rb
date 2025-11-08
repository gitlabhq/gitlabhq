# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Spec, feature_category: :pipeline_composition do
  let(:factory) { Gitlab::Config::Entry::Factory.new(described_class).value(spec_hash) }

  subject(:config) { factory.create!.tap(&:compose!) }

  context 'when spec contains default values for inputs' do
    let(:spec_hash) do
      {
        inputs: {
          foo: {
            default: 'bar'
          }
        }
      }
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the value' do
      expect(config.value).to eq(spec_hash)
    end
  end

  context 'when spec contains component configuration' do
    let(:spec_hash) do
      {
        component: %w[name sha version reference]
      }
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the component value' do
      expect(config.component_value).to match_array([:name, :sha, :version, :reference])
    end
  end

  context 'when spec contains both inputs and component' do
    let(:spec_hash) do
      {
        inputs: {
          foo: {
            default: 'bar'
          }
        },
        component: %w[name version]
      }
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns both values correctly' do
      expect(config.inputs_value).to eq({ foo: { default: 'bar' } })
      expect(config.component_value).to match_array([:name, :version])
    end
  end

  context 'when spec contains empty component array' do
    let(:spec_hash) do
      {
        component: []
      }
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns empty component value' do
      expect(config.component_value).to eq([])
    end
  end

  context 'when spec component is not specified' do
    let(:spec_hash) do
      {
        inputs: {
          foo: {
            default: 'bar'
          }
        }
      }
    end

    it 'returns default empty array for component' do
      expect(config.component_value).to eq([])
    end
  end

  context 'when spec contains a required value' do
    let(:spec_hash) do
      { inputs: { foo: nil } }
    end

    it 'parses the config correctly' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
      expect(config.value).to eq({ inputs: { foo: {} } })
    end
  end

  context 'when spec contains unknown keywords' do
    let(:spec_hash) { { test: 123 } }
    let(:expected_errors) { ['spec config contains unknown keys: test'] }

    it 'fails validations' do
      expect(config).not_to be_valid
      expect(config.errors).to eq(expected_errors)
    end

    it 'returns the value' do
      expect(config.value).to eq(spec_hash)
    end
  end

  context 'when spec contains include' do
    let(:spec_hash) do
      {
        inputs: {
          environment: { default: 'production' }
        },
        include: [
          { local: '/inputs.yml' }
        ]
      }
    end

    before do
      allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
        .with(:ci_file_inputs)
        .and_return(feature_flag_enabled)
    end

    context 'when ci_file_inputs feature flag is enabled' do
      let(:feature_flag_enabled) { true }

      it 'passes validations' do
        expect(config).to be_valid
        expect(config.errors).to be_empty
      end

      it 'returns the value with include' do
        expect(config.value).to eq(spec_hash)
      end

      it 'has include entry defined' do
        expect(config.include_value).to eq([{ local: '/inputs.yml' }])
      end
    end

    context 'when ci_file_inputs feature flag is disabled' do
      let(:feature_flag_enabled) { false }

      it 'fails validations' do
        expect(config).not_to be_valid
        expect(config.errors).to include('spec config contains unknown keys: include')
      end

      it 'still returns the value' do
        expect(config.value).to eq(spec_hash)
      end
    end
  end

  context 'when spec contains only include without inputs' do
    let(:spec_hash) do
      {
        include: [
          { local: '/inputs.yml' }
        ]
      }
    end

    before do
      allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
        .with(:ci_file_inputs)
        .and_return(true)
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the include value' do
      expect(config.include_value).to eq([{ local: '/inputs.yml' }])
    end
  end

  context 'when spec contains inputs, include, and component' do
    let(:spec_hash) do
      {
        inputs: {
          environment: { default: 'production' }
        },
        include: [
          { local: '/inputs.yml' }
        ],
        component: %w[name version]
      }
    end

    before do
      allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
        .with(:ci_file_inputs)
        .and_return(true)
    end

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns all values correctly' do
      expect(config.inputs_value).to eq({ environment: { default: 'production' } })
      expect(config.include_value).to eq([{ local: '/inputs.yml' }])
      expect(config.component_value).to match_array([:name, :version])
    end
  end
end
