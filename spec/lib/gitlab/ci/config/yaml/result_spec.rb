# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Result, feature_category: :pipeline_composition do
  it 'does not have a header when config is a single hash' do
    result = described_class.new({ a: 1, b: 2 })

    expect(result).not_to have_header
  end

  it 'has a header when config is an array of hashes' do
    result = described_class.new([{ a: 1 }, { b: 2 }])

    expect(result).to have_header
    expect(result.header).to eq({ a: 1 })
  end

  it 'raises an error when reading a header when there is none' do
    result = described_class.new({ b: 2 })

    expect { result.header }.to raise_error(ArgumentError)
  end

  it 'stores an error / exception when initialized with it' do
    result = described_class.new(error: ArgumentError.new('abc'))

    expect(result).not_to be_valid
    expect(result.error).to be_a ArgumentError
  end
end
