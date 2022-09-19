# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::LegacyVariables do
  let(:config) { {} }
  let(:metadata) { {} }

  subject(:entry) { described_class.new(config, **metadata) }

  before do
    entry.compose!
  end

  shared_examples 'valid config' do
    describe '#value' do
      it 'returns hash with key value strings' do
        expect(entry.value).to eq result
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  shared_examples 'invalid config' do |error_message|
    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors)
          .to include(error_message)
      end
    end
  end

  context 'when entry config value has key-value pairs' do
    let(:config) do
      { 'VARIABLE_1' => 'value 1', 'VARIABLE_2' => 'value 2' }
    end

    let(:result) do
      { 'VARIABLE_1' => 'value 1', 'VARIABLE_2' => 'value 2' }
    end

    it_behaves_like 'valid config'

    describe '#value_with_data' do
      it 'returns variable with data' do
        expect(entry.value_with_data).to eq(
          'VARIABLE_1' => { value: 'value 1' },
          'VARIABLE_2' => { value: 'value 2' }
        )
      end
    end
  end

  context 'with numeric keys and values in the config' do
    let(:config) { { 10 => 20 } }
    let(:result) do
      { '10' => '20' }
    end

    it_behaves_like 'valid config'
  end

  context 'when key is an array' do
    let(:config) { { ['VAR1'] => 'val1' } }
    let(:result) do
      { 'VAR1' => 'val1' }
    end

    it_behaves_like 'invalid config', /should be a hash of key value pairs/
  end

  context 'when value is a symbol' do
    let(:config) { { 'VAR1' => :val1 } }
    let(:result) do
      { 'VAR1' => 'val1' }
    end

    it_behaves_like 'valid config'
  end

  context 'when value is a boolean' do
    let(:config) { { 'VAR1' => true } }
    let(:result) do
      { 'VAR1' => 'val1' }
    end

    it_behaves_like 'invalid config', /should be a hash of key value pairs/
  end

  context 'when entry config value has key-value pair and hash' do
    let(:config) do
      { 'VARIABLE_1' => { value: 'value 1', description: 'variable 1' },
        'VARIABLE_2' => 'value 2' }
    end

    it_behaves_like 'invalid config', /should be a hash of key value pairs/

    context 'when metadata has use_value_data: true' do
      let(:metadata) { { use_value_data: true } }

      let(:result) do
        { 'VARIABLE_1' => 'value 1', 'VARIABLE_2' => 'value 2' }
      end

      it_behaves_like 'valid config'

      describe '#value_with_data' do
        it 'returns variable with data' do
          expect(entry.value_with_data).to eq(
            'VARIABLE_1' => { value: 'value 1', description: 'variable 1' },
            'VARIABLE_2' => { value: 'value 2' }
          )
        end
      end
    end
  end

  context 'when entry value is an array' do
    let(:config) { [:VAR, 'test'] }

    it_behaves_like 'invalid config', /should be a hash of key value pairs/
  end

  context 'when metadata has use_value_data: true' do
    let(:metadata) { { use_value_data: true } }

    context 'when entry value has hash with other key-pairs' do
      let(:config) do
        { 'VARIABLE_1' => { value: 'value 1', hello: 'variable 1' },
          'VARIABLE_2' => 'value 2' }
      end

      it_behaves_like 'invalid config', /should be a hash of key value pairs, value can be a hash/
    end

    context 'when entry config value has hash with nil description' do
      let(:config) do
        { 'VARIABLE_1' => { value: 'value 1', description: nil } }
      end

      it_behaves_like 'invalid config', /should be a hash of key value pairs, value can be a hash/
    end

    context 'when entry config value has hash without description' do
      let(:config) do
        { 'VARIABLE_1' => { value: 'value 1' } }
      end

      let(:result) do
        { 'VARIABLE_1' => 'value 1' }
      end

      it_behaves_like 'valid config'
    end
  end
end
