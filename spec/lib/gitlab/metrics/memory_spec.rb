# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Memory do
  describe '.gc_heap_fragmentation' do
    subject(:call) do
      described_class.gc_heap_fragmentation(
        heap_live_slots: gc_stat_heap_live_slots,
        heap_eden_pages: gc_stat_heap_eden_pages
      )
    end

    context 'when the Ruby heap is perfectly utilized' do
      # All objects are located in a single heap page.
      let(:gc_stat_heap_live_slots) { described_class::HEAP_SLOTS_PER_PAGE }
      let(:gc_stat_heap_eden_pages) { 1 }

      it { is_expected.to eq(0) }
    end

    context 'when the Ruby heap is greatly fragmented' do
      # There is one object per heap page.
      let(:gc_stat_heap_live_slots) { described_class::HEAP_SLOTS_PER_PAGE }
      let(:gc_stat_heap_eden_pages) { described_class::HEAP_SLOTS_PER_PAGE }

      # The heap can never be "perfectly fragmented" because that would require
      # zero objects per page.
      it { is_expected.to be > 0.99 }
    end

    context 'when the Ruby heap is semi-fragmented' do
      # All objects are spread over two pages i.e. each page is 50% utilized.
      let(:gc_stat_heap_live_slots) { described_class::HEAP_SLOTS_PER_PAGE }
      let(:gc_stat_heap_eden_pages) { 2 }

      it { is_expected.to eq(0.5) }
    end
  end
end
