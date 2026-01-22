# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::Boolean, feature_category: :pipeline_composition do
  describe '.build' do
    it 'creates a boolean lexeme for true' do
      lexeme = described_class.build('true')

      expect(lexeme.value).to be true
    end

    it 'creates a boolean lexeme for false' do
      lexeme = described_class.build('false')

      expect(lexeme.value).to be false
    end
  end

  describe '.type' do
    it 'is a value' do
      expect(described_class.type).to eq :value
    end
  end

  describe '#evaluate' do
    it 'returns true for true boolean' do
      lexeme = described_class.new(true)

      expect(lexeme.evaluate).to be true
    end

    it 'returns false for false boolean' do
      lexeme = described_class.new(false)

      expect(lexeme.evaluate).to be false
    end
  end

  describe '#inspect' do
    it 'returns "true" for true boolean' do
      lexeme = described_class.new(true)

      expect(lexeme.inspect).to eq 'true'
    end

    it 'returns "false" for false boolean' do
      lexeme = described_class.new(false)

      expect(lexeme.inspect).to eq 'false'
    end
  end
end
