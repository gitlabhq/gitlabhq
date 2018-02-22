require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Parser do
  describe '#tree' do
    context 'when using an operator' do
      it 'returns a reverse descent parse tree' do
        expect(described_class.new(tokens('$VAR == "123"')).tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Equals
      end
    end

    context 'when using a single token' do
      it 'returns a single token instance' do
        expect(described_class.new(tokens('$VAR')).tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Variable
      end
    end
  end

  def tokens(statement)
    Gitlab::Ci::Pipeline::Expression::Lexer.new(statement).tokens.to_enum
  end
end
