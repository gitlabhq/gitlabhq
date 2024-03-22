# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Block, feature_category: :pipeline_composition do
  subject { described_class.new(block, data, ctx) }

  let(:data) do
    'inputs.data'
  end

  let(:block) do
    "$[[ #{data} ]]"
  end

  let(:ctx) do
    { inputs: { data: 'abcdef' }, env: { 'ENV' => 'dev' } }
  end

  it 'knows its content' do
    expect(subject.content).to eq 'inputs.data'
  end

  it 'properly evaluates the access pattern' do
    expect(subject.value).to eq 'abcdef'
  end

  describe 'when functions are specified in the block' do
    let(:function_string1) { 'truncate(1,5)' }
    let(:data) { "inputs.data | #{function_string1}" }
    let(:access_value) { 'abcdef' }

    it 'returns the modified value' do
      expect(subject).to be_valid
      expect(subject.value).to eq('bcdef')
    end

    context 'when there is an access error' do
      let(:data) { "inputs.undefined | #{function_string1}" }

      it 'returns the access error' do
        expect(subject).not_to be_valid
        expect(subject.errors.first).to eq('unknown interpolation key: `undefined`')
      end
    end

    context 'when there is a function error' do
      let(:data) { 'inputs.data | undefined' }

      it 'returns the function error' do
        expect(subject).not_to be_valid
        expect(subject.errors.first).to match(/no function matching `undefined`/)
      end
    end

    context 'when multiple functions are specified' do
      let(:function_string2) { 'truncate(2,2)' }
      let(:data) { "inputs.data | #{function_string1} | #{function_string2}" }

      it 'executes each function in the specified order' do
        expect(subject.value).to eq('de')
      end

      context 'when the data has inconsistent spacing' do
        let(:data) { "inputs.data|#{function_string1}  | #{function_string2} " }

        it 'executes each function in the specified order' do
          expect(subject.value).to eq('de')
        end
      end

      context 'when a stack of functions errors in the middle' do
        let(:function_string2) { 'truncate(2)' }

        it 'does not modify the value' do
          expect(subject).not_to be_valid
          expect(subject.errors.first).to match(/no function matching `truncate\(2\)`/)
          expect(subject.instance_variable_get(:@value)).to be_nil
        end
      end

      context 'when too many functions are specified' do
        it 'returns error' do
          stub_const('Gitlab::Ci::Config::Interpolation::Block::MAX_FUNCTIONS', 1)

          expect(subject).not_to be_valid
          expect(subject.errors.first).to eq('too many functions in interpolation block')
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns the interpolation block' do
      expect(subject.to_s).to eq(block)
    end
  end

  describe '#length' do
    it 'returns the length of the interpolation block' do
      expect(subject.length).to eq(block.length)
    end
  end
end
