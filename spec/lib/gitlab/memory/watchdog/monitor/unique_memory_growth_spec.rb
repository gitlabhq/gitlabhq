# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/memory/watchdog/monitor_result_shared_examples'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Monitor::UniqueMemoryGrowth do
  let(:primary_memory) { 2048 }
  let(:worker_memory) { 0 }
  let(:max_mem_growth) { 2 }

  subject(:monitor) do
    described_class.new(max_mem_growth: max_mem_growth)
  end

  before do
    allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).and_return({ uss: worker_memory })
    allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(
      pid: Gitlab::Cluster::PRIMARY_PID
    ).and_return({ uss: primary_memory })
  end

  describe '#call' do
    it 'gets memory_usage_uss_pss' do
      expect(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(no_args)
      expect(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(pid: Gitlab::Cluster::PRIMARY_PID)

      monitor.call
    end

    context 'when monitor is called twice' do
      it 'reference memory is calculated only once' do
        expect(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(no_args).twice
        expect(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(pid: Gitlab::Cluster::PRIMARY_PID).once

        monitor.call
        monitor.call
      end
    end

    context 'when process exceeds threshold' do
      let(:worker_memory) { (max_mem_growth * primary_memory) + 1 }
      let(:payload) do
        {
          message: 'memory limit exceeded',
          memwd_max_uss_bytes: max_mem_growth * primary_memory,
          memwd_ref_uss_bytes: primary_memory,
          memwd_uss_bytes: worker_memory
        }
      end

      include_examples 'returns Watchdog Monitor result', threshold_violated: true
    end

    context 'when process does not exceed threshold' do
      let(:worker_memory) { (max_mem_growth * primary_memory) - 1 }
      let(:payload) { {} }

      include_examples 'returns Watchdog Monitor result', threshold_violated: false
    end
  end
end
