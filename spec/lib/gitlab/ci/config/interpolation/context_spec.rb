# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Context, feature_category: :pipeline_composition do
  subject { described_class.new(ctx) }

  let(:ctx) do
    { inputs: { key: 'abc' } }
  end

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
      expect { described_class.new(ctx) }
        .to raise_error(described_class::ContextTooComplexError)
    end
  end
end
