# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexer do
  let(:token_class) do
    Gitlab::Ci::Pipeline::Expression::Token
  end

  describe '#tokens' do
    it 'returns single value' do
      tokens = described_class.new('$VARIABLE').tokens

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'does ignore whitespace characters' do
      tokens = described_class.new("\t$VARIABLE ").tokens

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'returns multiple values of the same token' do
      tokens = described_class.new("$VARIABLE1 $VARIABLE2").tokens

      expect(tokens.size).to eq 2
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'returns multiple values with different tokens' do
      tokens = described_class.new('$VARIABLE "text" "value"').tokens

      expect(tokens.size).to eq 3
      expect(tokens.first.value).to eq '$VARIABLE'
      expect(tokens.second.value).to eq '"text"'
      expect(tokens.third.value).to eq '"value"'
    end

    it 'returns tokens and operators' do
      tokens = described_class.new('$VARIABLE == "text"').tokens

      expect(tokens.size).to eq 3
      expect(tokens.first.value).to eq '$VARIABLE'
      expect(tokens.second.value).to eq '=='
      expect(tokens.third.value).to eq '"text"'
    end

    it 'limits statement to specified amount of tokens' do
      lexer = described_class.new("$V1 $V2 $V3 $V4", max_tokens: 3)

      expect { lexer.tokens }
        .to raise_error described_class::SyntaxError
    end

    it 'raises syntax error in case of finding unknown tokens' do
      lexer = described_class.new('$V1 123 $V2')

      expect { lexer.tokens }
        .to raise_error described_class::SyntaxError
    end

    context 'with complex expressions' do
      using RSpec::Parameterized::TableSyntax

      subject { described_class.new(expression).tokens.map(&:value) }

      where(:expression, :tokens) do
        '$PRESENT_VARIABLE =~ /my var/ && $EMPTY_VARIABLE =~ /nope/' | ['$PRESENT_VARIABLE', '=~', '/my var/', '&&', '$EMPTY_VARIABLE', '=~', '/nope/']
        '$EMPTY_VARIABLE == "" && $PRESENT_VARIABLE'                 | ['$EMPTY_VARIABLE', '==', '""', '&&', '$PRESENT_VARIABLE']
        '$EMPTY_VARIABLE == "" && $PRESENT_VARIABLE != "nope"'       | ['$EMPTY_VARIABLE', '==', '""', '&&', '$PRESENT_VARIABLE', '!=', '"nope"']
        '$PRESENT_VARIABLE && $EMPTY_VARIABLE'                       | ['$PRESENT_VARIABLE', '&&', '$EMPTY_VARIABLE']
        '$PRESENT_VARIABLE =~ /my var/ || $EMPTY_VARIABLE =~ /nope/' | ['$PRESENT_VARIABLE', '=~', '/my var/', '||', '$EMPTY_VARIABLE', '=~', '/nope/']
        '$EMPTY_VARIABLE == "" || $PRESENT_VARIABLE'                 | ['$EMPTY_VARIABLE', '==', '""', '||', '$PRESENT_VARIABLE']
        '$EMPTY_VARIABLE == "" || $PRESENT_VARIABLE != "nope"'       | ['$EMPTY_VARIABLE', '==', '""', '||', '$PRESENT_VARIABLE', '!=', '"nope"']
        '$PRESENT_VARIABLE || $EMPTY_VARIABLE'                       | ['$PRESENT_VARIABLE', '||', '$EMPTY_VARIABLE']
        '$PRESENT_VARIABLE && null || $EMPTY_VARIABLE == ""'         | ['$PRESENT_VARIABLE', '&&', 'null', '||', '$EMPTY_VARIABLE', '==', '""']
      end

      with_them do
        it { is_expected.to eq(tokens) }
      end

      context 'with parentheses are used' do
        where(:expression, :tokens) do
          '($PRESENT_VARIABLE =~ /my var/) && $EMPTY_VARIABLE =~ /nope/' | ['(', '$PRESENT_VARIABLE', '=~', '/my var/', ')', '&&', '$EMPTY_VARIABLE', '=~', '/nope/']
          '$PRESENT_VARIABLE =~ /my var/ || ($EMPTY_VARIABLE =~ /nope/)' | ['$PRESENT_VARIABLE', '=~', '/my var/', '||', '(', '$EMPTY_VARIABLE', '=~', '/nope/', ')']
          '($PRESENT_VARIABLE && (null || $EMPTY_VARIABLE == ""))'       | ['(', '$PRESENT_VARIABLE', '&&', '(', 'null', '||', '$EMPTY_VARIABLE', '==', '""', ')', ')']
        end

        with_them do
          it { is_expected.to eq(tokens) }
        end
      end
    end
  end

  describe '#lexemes' do
    it 'returns an array of syntax lexemes' do
      lexer = described_class.new('$VAR "text"')

      expect(lexer.lexemes).to eq %w[variable string]
    end
  end
end
