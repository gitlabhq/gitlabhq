require 'spec_helper'

describe Gitlab::Ci::Pipeline::Expression::Lexeme::Variable do
  describe '.build' do
    it 'creates a new instance of the token' do
      expect(described_class.build('$VARIABLE'))
        .to be_a(described_class)
    end
  end

  describe '.type' do
    it 'is a value lexeme' do
      expect(described_class.type).to eq :value
    end
  end

  describe '#evaluate' do
    it 'returns variable value if it is defined' do
      variable = described_class.new('VARIABLE')

      expect(variable.evaluate(VARIABLE: 'my variable'))
        .to eq 'my variable'
    end

    it 'allows to use a string as a variable key too' do
      variable = described_class.new('VARIABLE')

      expect(variable.evaluate('VARIABLE' => 'my variable'))
        .to eq 'my variable'
    end

    it 'returns nil if it is not defined' do
      variable = described_class.new('VARIABLE')

      expect(variable.evaluate(OTHER: 'variable')).to be_nil
    end

    it 'returns an empty string if it is empty' do
      variable = described_class.new('VARIABLE')

      expect(variable.evaluate(VARIABLE: '')).to eq ''
    end
  end
end
