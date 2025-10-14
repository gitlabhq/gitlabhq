# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Context, feature_category: :pipeline_composition do
  subject { described_class.new(ctx, variables: variables) }

  let(:ctx) do
    { inputs: { key: 'abc' } }
  end

  let(:variables) { [] }

  describe '.fabricate' do
    context 'when given an unexpected object' do
      it 'raises an ArgumentError' do
        expect { described_class.fabricate([]) }.to raise_error(ArgumentError, 'unknown interpolation context')
      end
    end
  end

  describe '.new' do
    it 'returns variables as a Variables::Collection object' do
      expect(subject.variables.class).to eq(Gitlab::Ci::Variables::Collection)
    end
  end

  describe '#to_h' do
    it 'returns the context hash' do
      expect(subject.to_h).to eq(ctx)
    end
  end

  describe '#depth' do
    it 'returns a max depth of the hash' do
      expect(subject.depth).to eq 2
    end
  end

  context 'when interpolation context is too complex' do
    let(:ctx) do
      { inputs: { key: { aaa: { bbb: 'ccc' } } } }
    end

    it 'raises an exception' do
      expect { described_class.new(ctx, variables: variables) }
        .to raise_error(described_class::ContextTooComplexError)
    end
  end

  context 'when variables are provided' do
    let(:variables) do
      [
        { key: 'VAR1', value: 'value1' },
        { key: 'VAR2', value: 'value2' }
      ]
    end

    it 'stores variables as a Collection' do
      expect(subject.variables).to be_a(Gitlab::Ci::Variables::Collection)
      expect(subject.variables.to_hash).to include('VAR1' => 'value1', 'VAR2' => 'value2')
    end
  end

  describe '#fetch' do
    let(:ctx) do
      { inputs: { key: 'value' }, component: { name: 'test' } }
    end

    it 'fetches a field from the context' do
      expect(subject.fetch(:inputs)).to eq({ key: 'value' })
      expect(subject.fetch(:component)).to eq({ name: 'test' })
    end

    it 'raises KeyError when field does not exist' do
      expect { subject.fetch(:nonexistent) }.to raise_error(KeyError)
    end
  end

  describe '#key?' do
    let(:ctx) do
      { inputs: { key: 'value' }, component: { name: 'test' } }
    end

    it 'returns true for existing keys' do
      expect(subject.key?(:inputs)).to be true
      expect(subject.key?(:component)).to be true
    end

    it 'returns false for non-existing keys' do
      expect(subject.key?(:nonexistent)).to be false
    end
  end
end
