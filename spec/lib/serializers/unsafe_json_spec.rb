# frozen_string_literal: true

require 'fast_spec_helper'
require 'oj'

RSpec.describe Serializers::UnsafeJson do
  let(:result) { double(:result) }

  describe '.dump' do
    let(:obj) { { key: "value" } }

    it 'calls object#to_json with unsafe: true and returns the result' do
      expect(obj).to receive(:to_json).with(unsafe: true).and_return(result)
      expect(described_class.dump(obj)).to eq(result)
    end
  end

  describe '.load' do
    let(:data_string) { '{"key":"value","variables":[{"key":"VAR1","value":"VALUE1"}]}' }
    let(:data_hash) { Gitlab::Json.parse(data_string) }

    it 'calls JSON.load and returns the result' do
      expect(JSON).to receive(:load).with(data_hash).and_return(result)
      expect(described_class.load(data_hash)).to eq(result)
    end
  end
end
