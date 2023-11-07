# frozen_string_literal: true

require 'fast_spec_helper'
require 'prometheus/client'
require 'support/shared_examples/lib/gitlab/memory/watchdog/monitor_result_shared_examples'

RSpec.describe Gitlab::Memory::Watchdog::Monitor::RssMemoryLimit, feature_category: :cloud_connector do
  let(:max_rss_limit_gauge) { instance_double(::Prometheus::Client::Gauge) }
  let(:memory_limit_bytes) { 2_097_152_000 }
  let(:worker_memory_bytes) { 1_048_576_000 }

  subject(:monitor) do
    described_class.new(memory_limit_bytes: memory_limit_bytes)
  end

  before do
    allow(Gitlab::Metrics).to receive(:gauge)
      .with(:gitlab_memwd_max_memory_limit, anything)
      .and_return(max_rss_limit_gauge)
    allow(max_rss_limit_gauge).to receive(:set)
    allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).and_return({ total: worker_memory_bytes })
  end

  describe '#initialize' do
    it 'sets the max rss limit gauge' do
      expect(max_rss_limit_gauge).to receive(:set).with({}, memory_limit_bytes)

      monitor
    end
  end

  describe '#call' do
    context 'when process exceeds threshold' do
      let(:worker_memory_bytes) { memory_limit_bytes + 1 }
      let(:payload) do
        {
          message: 'rss memory limit exceeded',
          memwd_rss_bytes: worker_memory_bytes,
          memwd_max_rss_bytes: memory_limit_bytes
        }
      end

      include_examples 'returns Watchdog Monitor result', threshold_violated: true
    end

    context 'when process does not exceed threshold' do
      let(:worker_memory_bytes) { memory_limit_bytes - 1 }
      let(:payload) { {} }

      include_examples 'returns Watchdog Monitor result', threshold_violated: false
    end
  end
end
