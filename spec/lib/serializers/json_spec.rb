# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Serializers::Json do
  describe '.dump' do
    let(:obj) { { key: "value" } }

    subject { described_class.dump(obj) }

    it 'returns a hash' do
      is_expected.to eq(obj)
    end
  end

  describe '.load' do
    let(:data_string) { '{"key":"value","variables":[{"key":"VAR1","value":"VALUE1"}]}' }
    let(:data_hash) { Gitlab::Json.parse(data_string) }

    context 'when loading a hash' do
      subject { described_class.load(data_hash) }

      it 'decodes a string' do
        is_expected.to be_a(Hash)
      end

      it 'allows to access with symbols' do
        expect(subject[:key]).to eq('value')
        expect(subject[:variables].first[:key]).to eq('VAR1')
      end

      it 'allows to access with strings' do
        expect(subject["key"]).to eq('value')
        expect(subject["variables"].first["key"]).to eq('VAR1')
      end
    end

    context 'when loading a nil' do
      subject { described_class.load(nil) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end
end
