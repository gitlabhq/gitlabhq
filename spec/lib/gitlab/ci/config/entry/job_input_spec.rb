# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::JobInput, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory
      .new(described_class)
      .value(config)
      .with(key: input_name)
  end

  let(:input_name) { 'website' }
  let(:entry) { factory.create!.tap(&:compose!) }

  describe 'validations' do
    let(:required_config) { { default: 'default_value' } }

    it_behaves_like 'BaseInput'

    context 'when default is missing' do
      let(:config) { { type: 'string' } }

      it 'reports an error about the missing default' do
        expect(entry).not_to be_valid
        expect(entry.errors).to contain_exactly('website must have a default value')
      end
    end
  end

  describe '#value' do
    let(:config) do
      {
        default: 'staging',
        description: 'Environment name',
        options: %w[staging production],
        type: 'string'
      }
    end

    it 'returns the config hash' do
      expect(entry.value).to eq(config)
    end
  end
end
