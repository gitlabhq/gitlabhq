# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/memory/watchdog/monitor_result_shared_examples'

RSpec.describe Gitlab::Memory::Watchdog::Monitor::RssMemoryLimit do
  let(:memory_limit_bytes) { 2_097_152_000 }
  let(:worker_memory_bytes) { 1_048_576_000 }

  subject(:monitor) do
    described_class.new(memory_limit_bytes: memory_limit_bytes)
  end

  before do
    allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).and_return({ total: worker_memory_bytes })
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
