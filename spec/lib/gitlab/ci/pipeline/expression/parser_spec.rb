# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Parser do
  describe '#tree' do
    context 'validates simple operators' do
      using RSpec::Parameterized::TableSyntax

      where(:expression, :result_tree) do
        '$VAR1 == "123"' | 'equals($VAR1, "123")'
        '$VAR1 == "123" == $VAR2' | 'equals(equals($VAR1, "123"), $VAR2)'
        '$VAR' | '$VAR'
        '"some value"' | '"some value"'
        'null' | 'null'
        '$VAR1 || $VAR2 && $VAR3' | 'or($VAR1, and($VAR2, $VAR3))'
        '$VAR1 && $VAR2 || $VAR3' | 'or(and($VAR1, $VAR2), $VAR3)'
        '$VAR1 && $VAR2 || $VAR3 && $VAR4' | 'or(and($VAR1, $VAR2), and($VAR3, $VAR4))'
        '$VAR1 && ($VAR2 || $VAR3) && $VAR4' | 'and(and($VAR1, or($VAR2, $VAR3)), $VAR4)'
      end

      with_them do
        it { expect(described_class.seed(expression).tree.inspect).to eq(result_tree) }
      end
    end

    context 'when combining && and OR operators' do
      subject { described_class.seed('$VAR1 == "a" || $VAR2 == "b" && $VAR3 == "c" || $VAR4 == "d" && $VAR5 == "e"').tree }

      it 'returns operations in a correct order' do
        expect(subject.inspect)
          .to eq('or(or(equals($VAR1, "a"), and(equals($VAR2, "b"), equals($VAR3, "c"))), and(equals($VAR4, "d"), equals($VAR5, "e")))')
      end
    end

    context 'when using parenthesis' do
      subject { described_class.seed('(($VAR1 == "a" || $VAR2 == "b") && $VAR3 == "c" || $VAR4 == "d") && $VAR5 == "e"').tree }

      it 'returns operations in a correct order' do
        expect(subject.inspect)
          .to eq('and(or(and(or(equals($VAR1, "a"), equals($VAR2, "b")), equals($VAR3, "c")), equals($VAR4, "d")), equals($VAR5, "e"))')
      end
    end

    context 'when expression is empty' do
      it 'raises a parsing error' do
        expect { described_class.seed('').tree }
          .to raise_error Gitlab::Ci::Pipeline::Expression::Parser::ParseError
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

    context 'when parenthesis are unmatched' do
      where(:expression) do
        [
          '$VAR == (',
          '$VAR2 == ("aa"',
          '$VAR2 == ("aa"))',
          '$VAR2 == "aa")',
          '(($VAR2 == "aa")',
          '($VAR2 == "aa"))'
        ]
      end

      with_them do
        it 'raises a ParseError' do
          expect { described_class.seed(expression).tree }
            .to raise_error Gitlab::Ci::Pipeline::Expression::Parser::ParseError
        end
      end
    end
  end
end
