require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Statement do
  let(:pipeline) { build(:ci_pipeline) }
  let(:text) { '$VAR "text"' }

  subject do
    described_class.new(text, pipeline)
  end

  describe '#tokens' do
    it 'returns raw tokens' do
      expect(subject.tokens.size).to eq 2
    end
  end

  describe '#lexemes' do
    it 'returns an array of syntax lexemes' do
      expect(subject.lexemes).to eq %w[variable string]
    end
  end

  describe '#parse_tree' do
    context 'when expression grammar is incorrect' do
      it 'raises an error' do
        expect { subject.parse_tree }
          .to raise_error described_class::ParserError
      end
    end

    context 'when expression grammar is correct' do
      let(:text) { '$VAR == "value"' }

      it 'returns a reverse descent parse tree when using operator' do
        expect(subject.parse_tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Equals
      end
    end
  end
end
