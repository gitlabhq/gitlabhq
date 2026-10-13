# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Inputs, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory.new(described_class)
      .value(inputs_hash)
      .with(key: :inputs)
  end

  subject(:inputs) { factory.create! }

  before do
    inputs.compose!
  end

  context 'with valid inputs' do
    let(:inputs_hash) do
      {
        environment: {
          options: %w[development staging production]
        },
        region: {
          options: %w[us eu asia]
        }
      }
    end

    it { is_expected.to be_valid }
  end

  context 'with undefined input references' do
    let(:inputs_hash) do
      {
        environment: {
          options: %w[development production]
        },
        resource_tier: {
          rules: [
            {
              if: '$[[ inputs.undefined_input ]] == "value"',
              options: %w[small medium]
            }
          ]
        }
      }
    end

    it 'is invalid' do
      expect(inputs).not_to be_valid
      expect(inputs.errors.first).to include('rule[0] references undefined inputs: undefined_input')
    end
  end

  context 'with circular dependencies' do
    let(:inputs_hash) do
      {
        region: {
          rules: [{ if: '$[[ inputs.size ]] == "large"', options: %w[us] }]
        },
        size: {
          rules: [{ if: '$[[ inputs.region ]] == "us"', options: %w[large] }]
        }
      }
    end

    it 'is invalid' do
      expect(inputs).not_to be_valid
      expect(inputs.errors).to include(match(/circular dependency detected/))
    end
  end
end
