# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Interpolation::Context, feature_category: :pipeline_composition do
  subject { described_class.new(ctx) }

  let(:ctx) do
    { inputs: { key: 'abc' } }
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
