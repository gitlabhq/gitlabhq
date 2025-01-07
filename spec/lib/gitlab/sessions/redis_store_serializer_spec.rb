# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sessions::RedisStoreSerializer, feature_category: :system_access do
  let(:hash) { { a: 1, b: 2 } }
  let(:serialized) { Marshal.dump(val) }

  describe '.load' do
    shared_examples 'unmarshal' do
      it 'returns original value' do
        expect(load).to eq(expected)
      end
    end

    subject(:load) { described_class.load(serialized) }

    context 'with hash value' do
      let(:val) { hash }
      let(:expected) { hash }

      it_behaves_like 'unmarshal'
    end

    context 'with ActiveSupport::Cache::Entry value' do
      let(:val) { ActiveSupport::Cache::Entry.new(hash) }
      let(:expected) { hash }

      it_behaves_like 'unmarshal'
    end

    context 'with nil value' do
      let(:val) { nil }
      let(:expected) { nil }

      it_behaves_like 'unmarshal'
    end

    context 'with unrecognized type' do
      let(:val) { %w[a b c] }

      it 'tracks and raises an exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_exception).with(instance_of(NoMethodError))

        load
      end
    end
  end

  describe '.dump' do
    subject(:dump) { described_class.dump(hash) }

    it 'calls Marshal.dump' do
      expect(Marshal).to receive(:dump).with(hash)

      dump
    end

    it 'returns marshalled object' do
      expect(dump).to eq(Marshal.dump(hash))
    end
  end
end
