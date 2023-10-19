# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::FunctionsStack, feature_category: :pipeline_composition do
  let(:functions) { ['truncate(0,4)', 'truncate(1,2)'] }
  let(:input_value) { 'test_input_value' }

  subject { described_class.new(functions, nil).evaluate(input_value) }

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
end
