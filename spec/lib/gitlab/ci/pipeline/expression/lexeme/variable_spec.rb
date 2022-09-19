# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::Variable do
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
    let(:lexeme) { described_class.new('VARIABLE') }

    it 'returns variable value if it is defined' do
      expect(lexeme.evaluate(VARIABLE: 'my variable'))
        .to eq 'my variable'
    end

    it 'allows to use a string as a variable key too' do
      expect(lexeme.evaluate('VARIABLE' => 'my variable'))
        .to eq 'my variable'
    end

    it 'returns nil if it is not defined' do
      expect(lexeme.evaluate('OTHER' => 'variable')).to be_nil
      expect(lexeme.evaluate(OTHER: 'variable')).to be_nil
    end

    it 'returns an empty string if it is empty' do
      expect(lexeme.evaluate('VARIABLE' => '')).to eq ''
      expect(lexeme.evaluate(VARIABLE: '')).to eq ''
    end

    it 'does not call with_indifferent_access unnecessarily' do
      variables_hash = { VARIABLE: 'my variable' }.with_indifferent_access

      expect(variables_hash).not_to receive(:with_indifferent_access)
      expect(lexeme.evaluate(variables_hash)).to eq 'my variable'
    end
  end
end
