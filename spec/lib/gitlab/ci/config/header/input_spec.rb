# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Header::Input, feature_category: :pipeline_composition do
  let(:factory) do
    Gitlab::Config::Entry::Factory
      .new(described_class)
      .value(input_hash)
      .with(key: input_name)
  end

  let(:input_name) { 'foo' }

  subject(:config) { factory.create!.tap(&:compose!) }

  shared_examples 'a valid input' do
    let(:expected_hash) { input_hash }

    it 'passes validations' do
      expect(config).to be_valid
      expect(config.errors).to be_empty
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  shared_examples 'an invalid input' do
    let(:expected_hash) { input_hash }

    it 'fails validations' do
      expect(config).not_to be_valid
      expect(config.errors).to eq(expected_errors)
    end

    it 'returns the value' do
      expect(config.value).to eq(expected_hash)
    end
  end

  context 'when has a default value' do
    let(:input_hash) { { default: 'bar' } }

    it_behaves_like 'a valid input'
  end

  context 'when is a required required input' do
    let(:input_hash) { nil }

    it_behaves_like 'a valid input'
  end

  context 'when contains unknown keywords' do
    let(:input_hash) { { test: 123 } }
    let(:expected_errors) { ['foo config contains unknown keys: test'] }

    it_behaves_like 'an invalid input'
  end

  context 'when has invalid name' do
    let(:input_name) { [123] }
    let(:input_hash) { {} }

    let(:expected_errors) { ['123 key must be an alphanumeric string'] }

    it_behaves_like 'an invalid input'
  end
end
