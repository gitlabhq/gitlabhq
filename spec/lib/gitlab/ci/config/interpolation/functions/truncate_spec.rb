# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Functions::Truncate, feature_category: :pipeline_composition do
  it 'matches exactly the truncate function with 2 numeric arguments' do
    expect(described_class.matches?('truncate(1,2)')).to be_truthy
    expect(described_class.matches?('truncate( 11 , 222 )')).to be_truthy
    expect(described_class.matches?('truncate( string , 222 )')).to be_falsey
    expect(described_class.matches?('truncate(222)')).to be_falsey
    expect(described_class.matches?('unknown(1,2)')).to be_falsey
  end

  it 'truncates the given input' do
    function = described_class.new('truncate(1,2)', nil)

    output = function.execute('test')

    expect(function).to be_valid
    expect(output).to eq('es')
  end

  context 'when given a non-string input' do
    it 'returns an error' do
      function = described_class.new('truncate(1,2)', nil)

      function.execute(100)

      expect(function).not_to be_valid
      expect(function.errors).to contain_exactly(
        'error in `truncate` function: invalid input type: truncate can only be used with string inputs'
      )
    end
  end
end
