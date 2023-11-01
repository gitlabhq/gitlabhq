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

  context 'when has a string default value' do
    let(:input_hash) { { default: 'bar' } }

    it_behaves_like 'a valid input'
  end

  context 'when has a numeric default value' do
    let(:input_hash) { { default: 6.66 } }

    it_behaves_like 'a valid input'
  end

  context 'when has a boolean default value' do
    let(:input_hash) { { default: true } }

    it_behaves_like 'a valid input'
  end

  context 'when has a description value' do
    let(:input_hash) { { description: 'bar' } }

    it_behaves_like 'a valid input'
  end

  context 'when is a required input' do
    let(:input_hash) { nil }

    it_behaves_like 'a valid input'
  end

  context 'when given a valid type' do
    where(:input_type) { ::Gitlab::Ci::Config::Interpolation::Inputs.input_types }

    with_them do
      let(:input_hash) { { type: input_type } }

      it_behaves_like 'a valid input'
    end
  end

  context 'when the input has RegEx validation' do
    let(:input_hash) { { regex: '\w+' } }

    it_behaves_like 'a valid input'
  end

  context 'when given an invalid type' do
    let(:input_hash) { { type: 'datetime' } }
    let(:expected_errors) { ['foo input type unknown value: datetime'] }

    it_behaves_like 'an invalid input'
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

  context 'when RegEx validation value is not a string' do
    let(:input_hash) { { regex: [] } }
    let(:expected_errors) { ['foo input regex should be a string'] }

    it_behaves_like 'an invalid input'
  end

  context 'when the limit for allowed number of options is reached' do
    let(:limit) { described_class::ALLOWED_OPTIONS_LIMIT }
    let(:input_hash) { { default: 'value1', options: options  } }
    let(:options) { Array.new(limit.next) { |i| "value#{i}" } }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'returns error about incorrect type' do
        expect(config.errors).to contain_exactly(
          "foo config cannot define more than #{limit} options")
      end
    end
  end
end
