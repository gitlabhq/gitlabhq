# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::RateLimitingGates, :request_store do
  describe '.gates' do
    it 'returns an empty array when no gates are tracked' do
      expect(described_class.gates).to eq([])
    end

    it 'returns all gates used in the request' do
      described_class.track(:foo)

      RequestStore.clear!

      described_class.track(:bar)
      described_class.track(:baz)

      expect(described_class.gates).to contain_exactly(:bar, :baz)
    end

    it 'deduplicates its results' do
      described_class.track(:foo)
      described_class.track(:bar)
      described_class.track(:foo)

      expect(described_class.gates).to contain_exactly(:foo, :bar)
    end
  end

  describe '.payload' do
    it 'returns the gates in a hash' do
      described_class.track(:foo)
      described_class.track(:bar)

      expect(described_class.payload).to eq(described_class::GATES => [:foo, :bar])
    end
  end
end
