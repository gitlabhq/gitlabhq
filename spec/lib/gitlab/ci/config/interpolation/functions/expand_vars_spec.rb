# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Functions::ExpandVars, feature_category: :pipeline_composition do
  let(:variables) do
    Gitlab::Ci::Variables::Collection.new([
      { key: 'VAR1', value: 'value1', masked: false },
      { key: 'VAR2', value: 'value2', masked: false },
      { key: 'NESTED_VAR', value: '$MY_VAR', masked: false },
      { key: 'MASKED_VAR', value: 'masked', masked: true }
    ])
  end

  let(:function_expression) { 'expand_vars' }
  let(:ctx) { Gitlab::Ci::Config::Interpolation::Context.new({}, variables: variables) }

  subject(:function) { described_class.new(function_expression, ctx) }

  describe '#execute' do
    let(:input_value) { '$VAR1' }

    subject(:execute) { function.execute(input_value) }

    it 'expands the variable' do
      expect(execute).to eq('value1')
      expect(function).to be_valid
    end

    context 'when the variable contains another variable' do
      let(:input_value) { '$NESTED_VAR' }

      it 'does not expand the inner variable' do
        expect(execute).to eq('$MY_VAR')
        expect(function).to be_valid
      end
    end

    context 'when the variable is masked' do
      let(:input_value) { '$MASKED_VAR' }

      it 'returns an error' do
        expect(execute).to be_nil
        expect(function).not_to be_valid
        expect(function.errors).to contain_exactly(
          'error in `expand_vars` function: variable expansion error: masked variables cannot be expanded'
        )
      end
    end

    context 'when the variable is unknown' do
      let(:input_value) { '$UNKNOWN_VAR' }

      it 'does not expand the variable' do
        expect(execute).to eq('$UNKNOWN_VAR')
        expect(function).to be_valid
      end
    end

    context 'when there are multiple variables' do
      let(:input_value) { '${VAR1} $VAR2 %VAR1%' }

      it 'expands the variables' do
        expect(execute).to eq('value1 value2 value1')
        expect(function).to be_valid
      end
    end

    context 'when the input is not a string' do
      let(:input_value) { 100 }

      it 'returns an error' do
        expect(execute).to be_nil
        expect(function).not_to be_valid
        expect(function.errors).to contain_exactly(
          'error in `expand_vars` function: invalid input type: expand_vars can only be used with string inputs'
        )
      end
    end
  end

  describe '.matches?' do
    it 'matches exactly the expand_vars function with no arguments' do
      expect(described_class.matches?('expand_vars')).to be_truthy
      expect(described_class.matches?('expand_vars()')).to be_falsey
      expect(described_class.matches?('expand_vars(1)')).to be_falsey
      expect(described_class.matches?('unknown')).to be_falsey
    end
  end
end
