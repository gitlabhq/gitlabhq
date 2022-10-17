# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/memory/watchdog/monitor_result_shared_examples'
require 'prometheus/client'

RSpec.describe Gitlab::Memory::Watchdog::Monitor::HeapFragmentation do
  let(:heap_frag_limit_gauge) { instance_double(::Prometheus::Client::Gauge) }
  let(:max_heap_fragmentation) { 0.2 }
  let(:fragmentation) { 0.3 }

  subject(:monitor) do
    described_class.new(max_heap_fragmentation: max_heap_fragmentation)
  end

  before do
    allow(Gitlab::Metrics).to receive(:gauge)
      .with(:gitlab_memwd_heap_frag_limit, anything)
      .and_return(heap_frag_limit_gauge)
    allow(heap_frag_limit_gauge).to receive(:set)

    allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(fragmentation)
  end

  describe '#initialize' do
    it 'sets the heap fragmentation limit gauge' do
      expect(heap_frag_limit_gauge).to receive(:set).with({}, max_heap_fragmentation)

      monitor
    end
  end

  describe '#call' do
    it 'gets gc_heap_fragmentation' do
      expect(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation)

      monitor.call
    end

    context 'when process exceeds threshold' do
      let(:fragmentation) { max_heap_fragmentation + 0.1 }
      let(:payload) do
        {
          message: 'heap fragmentation limit exceeded',
          memwd_cur_heap_frag: fragmentation,
          memwd_max_heap_frag: max_heap_fragmentation
        }
      end

      include_examples 'returns Watchdog Monitor result', threshold_violated: true
    end

    context 'when process does not exceed threshold' do
      let(:fragmentation) { max_heap_fragmentation - 0.1 }
      let(:payload) { {} }

      include_examples 'returns Watchdog Monitor result', threshold_violated: false
    end
  end
end
