# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Ci::Inputs::RulesEvaluator, feature_category: :pipeline_composition do
  let(:current_inputs) { { 'environment' => 'production' } }
  let(:evaluator) { described_class.new(rules, current_inputs) }

  describe '#resolved_options' do
    context 'when a rule condition matches' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "production"', options: %w[large xlarge] },
          { if: '$[[ inputs.environment ]] == "staging"', options: %w[small medium] }
        ]
      end

      it 'returns options from the first matching rule' do
        expect(evaluator.resolved_options).to eq(%w[large xlarge])
      end
    end

    context 'when no rule condition matches' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "development"', options: %w[tiny] }
        ]
      end

      it 'returns nil' do
        expect(evaluator.resolved_options).to be_nil
      end
    end

    context 'when a fallback rule exists' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "staging"', options: %w[small] },
          { options: %w[medium large] }
        ]
      end

      it 'returns options from the fallback rule' do
        expect(evaluator.resolved_options).to eq(%w[medium large])
      end
    end

    context 'when rule condition has invalid syntax' do
      let(:rules) do
        [
          { if: '&&&&', options: %w[invalid] },
          { options: %w[fallback] }
        ]
      end

      it 'skips the invalid rule and uses fallback' do
        expect(evaluator.resolved_options).to eq(%w[fallback])
      end
    end
  end

  describe '#resolved_default' do
    context 'when a rule condition matches' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "production"', default: 'prod-default' },
          { if: '$[[ inputs.environment ]] == "staging"', default: 'staging-default' }
        ]
      end

      it 'returns default from the first matching rule' do
        expect(evaluator.resolved_default).to eq('prod-default')
      end
    end

    context 'when no rule has a default' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "production"', options: %w[a b] }
        ]
      end

      it 'returns nil' do
        expect(evaluator.resolved_default).to be_nil
      end
    end

    context 'when fallback rule has a default' do
      let(:rules) do
        [
          { if: '$[[ inputs.environment ]] == "staging"', default: 'staging' },
          { default: 'fallback-default' }
        ]
      end

      it 'returns default from the fallback rule' do
        expect(evaluator.resolved_default).to eq('fallback-default')
      end
    end
  end

  context 'when rules is nil' do
    let(:rules) { nil }

    it 'returns nil for resolved_options' do
      expect(evaluator.resolved_options).to be_nil
    end

    it 'returns nil for resolved_default' do
      expect(evaluator.resolved_default).to be_nil
    end
  end

  context 'when rules is empty array' do
    let(:rules) { [] }

    it 'returns nil for resolved_options' do
      expect(evaluator.resolved_options).to be_nil
    end

    it 'returns nil for resolved_default' do
      expect(evaluator.resolved_default).to be_nil
    end
  end

  context 'when current_inputs is nil' do
    let(:current_inputs) { nil }
    let(:rules) do
      [
        { options: %w[fallback] }
      ]
    end

    it 'uses fallback rule when no inputs available' do
      expect(evaluator.resolved_options).to eq(%w[fallback])
    end
  end

  context 'when multiple rules match' do
    let(:rules) do
      [
        { if: '$[[ inputs.environment ]] == "production"', default: 'first' },
        { if: 'true', default: 'second' },
        { default: 'third' }
      ]
    end

    it 'returns the first matching rule' do
      expect(evaluator.resolved_default).to eq('first')
    end
  end

  context 'when condition references undefined input' do
    let(:rules) do
      [
        { if: '$[[ inputs.undefined_input ]] == "value"', options: %w[a] },
        { options: %w[fallback] }
      ]
    end

    it 'treats undefined input as falsy and uses fallback' do
      expect(evaluator.resolved_options).to eq(%w[fallback])
    end
  end

  context 'when rule has both options and default' do
    let(:rules) do
      [
        { if: '$[[ inputs.environment ]] == "production"', options: %w[a b], default: 'a' }
      ]
    end

    it 'returns both options and default from the same rule' do
      expect(evaluator.resolved_options).to eq(%w[a b])
      expect(evaluator.resolved_default).to eq('a')
    end
  end
end
