require 'fast_spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Parser do
  describe '#tree' do
    context 'when using two operators' do
      it 'returns a reverse descent parse tree' do
        expect(described_class.seed('$VAR1 == "123"').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Equals
      end
    end

    context 'when using three operators' do
      it 'returns a reverse descent parse tree' do
        expect(described_class.seed('$VAR1 == "123" == $VAR2').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Equals
      end
    end

    context 'when using a single variable token' do
      it 'returns a single token instance' do
        expect(described_class.seed('$VAR').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Variable
      end
    end

    context 'when using a single string token' do
      it 'returns a single token instance' do
        expect(described_class.seed('"some value"').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::String
      end
    end

    context 'when expression is empty' do
      it 'returns a null token' do
        expect { described_class.seed('').tree }
          .to raise_error Gitlab::Ci::Pipeline::Expression::Parser::ParseError
      end
    end

    context 'when expression is null' do
      it 'returns a null token' do
        expect(described_class.seed('null').tree)
          .to be_a Gitlab::Ci::Pipeline::Expression::Lexeme::Null
      end
    end

    context 'when two value tokens have no operator' do
      it 'raises a parsing error' do
        expect { described_class.seed('$VAR "text"').tree }
          .to raise_error Gitlab::Ci::Pipeline::Expression::Parser::ParseError
      end
    end

    context 'when an operator has no left side' do
      it 'raises an OperatorError' do
        expect { described_class.seed('== "123"').tree }
            .to raise_error Gitlab::Ci::Pipeline::Expression::Lexeme::Operator::OperatorError
      end
    end

    context 'when an operator has no right side' do
      it 'raises an OperatorError' do
        expect { described_class.seed('$VAR ==').tree }
            .to raise_error Gitlab::Ci::Pipeline::Expression::Lexeme::Operator::OperatorError
      end
    end
  end
end
