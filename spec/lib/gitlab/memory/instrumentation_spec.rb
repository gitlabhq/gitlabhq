# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Instrumentation, feature_category: :cloud_connector do
  include MemoryInstrumentationHelper

  before do
    verify_memory_instrumentation_available!
  end

  describe '.available?' do
    it 'returns true' do
      expect(described_class).to be_available
    end
  end

  describe '.start_thread_memory_allocations' do
    subject { described_class.start_thread_memory_allocations }

    it 'a hash is returned' do
      is_expected.to be_a(Hash)
    end

    context 'when feature is unavailable' do
      before do
        allow(described_class).to receive(:available?) { false }
      end

      it 'a nil is returned' do
        is_expected.to be_nil
      end
    end
  end

  describe '.with_memory_allocations' do
    let(:ntimes) { 100 }

    subject do
      described_class.with_memory_allocations do
        Array.new(1000).map { '0' * 1000 }
      end
    end

    before do
      expect(described_class).to receive(:start_thread_memory_allocations).and_call_original
      expect(described_class).to receive(:measure_thread_memory_allocations).and_call_original
    end

    it 'a hash is returned' do
      result = subject
      expect(result).to include(
        mem_objects: be > 1000,
        mem_mallocs: be > 1000,
        mem_bytes: be > 1000_000, # 1000 items * 1000 bytes each
        mem_total_bytes: eq(result[:mem_bytes] + (40 * result[:mem_objects]))
      )
    end

    context 'when feature is unavailable' do
      before do
        allow(described_class).to receive(:available?) { false }
      end

      it 'a nil is returned' do
        is_expected.to be_nil
      end
    end
  end
end
