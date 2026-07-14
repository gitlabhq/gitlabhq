# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::FunctionsStack, feature_category: :pipeline_composition do
  let(:functions) { ['truncate(0,4)', 'truncate(1,2)'] }
  let(:input_value) { 'test_input_value' }

  subject { described_class.new(functions, nil).evaluate(input_value) }

  before do
    allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
      .with(:ci_interpolation_split_function)
      .and_return(false)
  end

  it 'modifies the given input value according to the function expressions' do
    expect(subject).to be_success
    expect(subject.value).to eq('es')
  end

  context 'when applying a function fails' do
    let(:input_value) { 666 }

    it 'returns the error given by the failure' do
      expect(subject).not_to be_success
      expect(subject.errors).to contain_exactly(
        'error in `truncate` function: invalid input type: truncate can only be used with string inputs'
      )
    end
  end

  context 'when function expressions do not match any function' do
    let(:functions) { ['truncate(0)', 'unknown'] }

    it 'returns an error' do
      expect(subject).not_to be_success
      expect(subject.errors).to contain_exactly(
        'no function matching `truncate(0)`: check that the function name, arguments, and types are correct',
        'no function matching `unknown`: check that the function name, arguments, and types are correct'
      )
    end
  end

  context 'when ci_interpolation_split_function feature flag is enabled' do
    before do
      allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
        .with(:ci_interpolation_split_function)
        .and_return(true)
    end

    context 'when split is the last function' do
      let(:functions) { ["split(',')"] }
      let(:input_value) { 'a,b,c' }

      it 'splits the input string into an array' do
        expect(subject).to be_success
        expect(subject.value).to eq(%w[a b c])
      end
    end

    context 'when split is not the last function in the chain' do
      let(:functions) { ["split(',')", 'truncate(0,1)'] }
      let(:input_value) { 'a,b,c' }

      it 'returns an error' do
        expect(subject).not_to be_success
        expect(subject.errors).to contain_exactly(
          'split() must be the last function in a chain (it returns an array, not a string)'
        )
      end
    end
  end

  context 'when ci_interpolation_split_function feature flag is disabled' do
    let(:functions) { ["split(',')"] }
    let(:input_value) { 'a,b,c' }

    it 'returns an error for split expressions' do
      expect(subject).not_to be_success
      expect(subject.errors).to contain_exactly(
        "no function matching `split(',')`: check that the function name, arguments, and types are correct"
      )
    end
  end
end
