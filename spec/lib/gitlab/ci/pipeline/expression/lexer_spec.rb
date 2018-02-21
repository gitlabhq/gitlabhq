require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexer do
  let(:token_class) do
    Gitlab::Ci::Pipeline::Expression::Token
  end

  describe '#tokenize' do
    it 'tokenizes single value' do
      tokens = described_class.new('$VARIABLE').tokenize

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'does ignore whitespace characters' do
      tokens = described_class.new("\t$VARIABLE ").tokenize

      expect(tokens).to be_one
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'tokenizes multiple values of the same token' do
      tokens = described_class.new("$VARIABLE1 $VARIABLE2").tokenize

      expect(tokens.size).to eq 2
      expect(tokens).to all(be_an_instance_of(token_class))
    end

    it 'tokenizes multiple values with different tokens' do
      tokens = described_class.new('$VARIABLE "text" "value"').tokenize

      expect(tokens.size).to eq 3
      expect(tokens.first.value).to eq '$VARIABLE'
      expect(tokens.second.value).to eq '"text"'
      expect(tokens.third.value).to eq '"value"'
    end

    it 'limits statement to 5 tokens' do
      lexer = described_class.new("$V1 $V2 $V3 $V4 $V5 $V6")

      expect { lexer.tokenize }
        .to raise_error described_class::SyntaxError
    end

    it 'raises syntax error in case of finding unknown tokens' do
      lexer = described_class.new('$V1 123 $V2')

      expect { lexer.tokenize }
        .to raise_error described_class::SyntaxError
    end
  end
end
