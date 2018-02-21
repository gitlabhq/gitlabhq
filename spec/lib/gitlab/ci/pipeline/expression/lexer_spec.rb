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
  end
end
