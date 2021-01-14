# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Variables do
  let(:metadata) { {} }

  subject { described_class.new(config, **metadata) }

  shared_examples 'valid config' do
    describe '#value' do
      it 'returns hash with key value strings' do
        expect(subject.value).to eq result
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(subject.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  shared_examples 'invalid config' do
    describe '#valid?' do
      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    describe '#errors' do
      it 'saves errors' do
        expect(subject.errors)
          .to include /should be a hash of key value pairs/
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
  end

  context 'with numeric keys and values in the config' do
    let(:config) { { 10 => 20 } }
    let(:result) do
      { '10' => '20' }
    end

    it_behaves_like 'valid config'
  end

  context 'when entry config value has key-value pair and hash' do
    let(:config) do
      { 'VARIABLE_1' => { value: 'value 1', description: 'variable 1' },
        'VARIABLE_2' => 'value 2' }
    end

    let(:result) do
      { 'VARIABLE_1' => 'value 1', 'VARIABLE_2' => 'value 2' }
    end

    it_behaves_like 'invalid config'

    context 'when metadata has use_value_data' do
      let(:metadata) { { use_value_data: true } }

      it_behaves_like 'valid config'
    end
  end

  context 'when entry value is an array' do
    let(:config) { [:VAR, 'test'] }

    it_behaves_like 'invalid config'
  end

  context 'when metadata has use_value_data' do
    let(:metadata) { { use_value_data: true } }

    context 'when entry value has hash with other key-pairs' do
      let(:config) do
        { 'VARIABLE_1' => { value: 'value 1', hello: 'variable 1' },
          'VARIABLE_2' => 'value 2' }
      end

      it_behaves_like 'invalid config'
    end

    context 'when entry config value has hash with nil description' do
      let(:config) do
        { 'VARIABLE_1' => { value: 'value 1', description: nil } }
      end

      it_behaves_like 'invalid config'
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
