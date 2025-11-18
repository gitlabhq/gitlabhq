# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Lexeme::Input, feature_category: :pipeline_composition do
  describe '.build' do
    it 'extracts the input name' do
      lexeme = described_class.build('$[[ inputs.environment ]]')

      expect(lexeme.value).to eq('environment')
    end

    it 'handles input names with whitespace in brackets' do
      lexeme = described_class.build('$[[  inputs.environment  ]]')

      expect(lexeme.value).to eq('environment')
    end
  end

  describe '.type' do
    it 'is a value' do
      expect(described_class.type).to eq :value
    end
  end

  describe '#evaluate' do
    let(:lexeme) { described_class.new('environment') }

    it 'returns input value if it is defined' do
      expect(lexeme.evaluate(inputs: { 'environment' => 'production' })).to eq 'production'
    end

    it 'allows to use a symbol as an input key too' do
      expect(lexeme.evaluate(inputs: { environment: 'production' })).to eq 'production'
    end

    it 'returns nil if it is not defined' do
      expect(lexeme.evaluate(inputs: { 'region' => 'us-west' })).to be_nil
      expect(lexeme.evaluate(inputs: { region: 'us-west' })).to be_nil
    end

    it 'returns nil when no inputs are provided' do
      expect(lexeme.evaluate({})).to be_nil
      expect(lexeme.evaluate).to be_nil
    end

    it 'does not call with_indifferent_access unnecessarily' do
      inputs_hash = { inputs: { environment: 'production' }.with_indifferent_access }

      expect(inputs_hash[:inputs]).not_to receive(:with_indifferent_access)
      expect(lexeme.evaluate(inputs_hash)).to eq 'production'
    end
  end

  describe '#inspect' do
    let(:lexeme) { described_class.new('environment') }

    it 'returns the input reference format' do
      expect(lexeme.inspect).to eq '$[[ inputs.environment ]]'
    end
  end
end
