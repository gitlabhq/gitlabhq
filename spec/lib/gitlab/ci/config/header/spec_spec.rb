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
end
