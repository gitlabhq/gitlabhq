require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::String do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('"my string"'))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '#evaluate' do
    it 'returns string value it is is present' do
      string = described_class.new('my string')

      expect(string.evaluate).to eq 'my string'
    end

    it 'returns an empty string if it is empty' do
      string = described_class.new('')

      expect(string.evaluate).to eq ''
    end
  end
end
