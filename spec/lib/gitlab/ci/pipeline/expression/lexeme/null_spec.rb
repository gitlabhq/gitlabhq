require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Null do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('null'))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '#evaluate' do
    it 'always evaluates to `nil`' do
      expect(described_class.new('null').evaluate).to be_nil
    end
  end
end
