# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Yaml::Result, feature_category: :pipeline_composition do
  it 'does not have a header when config is a single hash' do
    result = described_class.new(config: { a: 1, b: 2 })

    expect(result).not_to have_header
  end

  context 'when config is an array of hashes' do
    context 'when first document matches the header schema' do
      it 'has a header' do
        result = described_class.new(config: [{ spec: { inputs: {} } }, { b: 2 }])

        expect(result).to have_header
        expect(result.header).to eq({ spec: { inputs: {} } })
        expect(result.content).to eq({ b: 2 })
      end
    end

    context 'when first document does not match the header schema' do
      it 'does not have header' do
        result = described_class.new(config: [{ a: 1 }, { b: 2 }])

        expect(result).not_to have_header
        expect(result.content).to eq({ a: 1 })
      end
    end
  end

  context 'when the first document is undefined' do
    it 'does not have header' do
      result = described_class.new(config: [nil, { a: 1 }])

      expect(result).not_to have_header
      expect(result.content).to be_nil
    end
  end

  it 'raises an error when reading a header when there is none' do
    result = described_class.new(config: { b: 2 })

    expect { result.header }.to raise_error(ArgumentError)
  end

  it 'stores an error / exception when initialized with it' do
    result = described_class.new(error: ArgumentError.new('abc'))

    expect(result).not_to be_valid
    expect(result.error).to be_a ArgumentError
  end
end
