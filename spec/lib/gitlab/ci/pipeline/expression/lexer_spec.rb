require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexer do
  let(:token_class) do
    Gitlab::Ci::Pipeline::Expression::Token
  end

  describe '#tokens' do
    it 'tokenss single value' do
      tokens = described_class.new('$VARIABLE').tokens

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'does ignore whitespace characters' do
      tokens = described_class.new("\t$VARIABLE ").tokens

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'tokenss multiple values of the same token' do
      tokens = described_class.new("$VARIABLE1 $VARIABLE2").tokens

      expect(tokens.size).to eq 2
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'tokenss multiple values with different tokens' do
      tokens = described_class.new('$VARIABLE "text" "value"').tokens

      expect(tokens.size).to eq 3
      expect(tokens.first.value).to eq '$VARIABLE'
      expect(tokens.second.value).to eq '"text"'
      expect(tokens.third.value).to eq '"value"'
    end

    it 'tokenss tokens and operators' do
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
  end

  describe '#lexemes' do
    it 'returns an array of syntax lexemes' do
      lexer = described_class.new('$VAR "text"')

      expect(lexer.lexemes).to eq %w[variable string]
    end
  end
end
