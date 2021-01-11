# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled do
  include ExclusiveLeaseHelpers

  let(:peek_adapter) do
    Class.new do
      prepend Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled

      def initialize(client)
        @client = client
      end

      def save(id)
        # no-op
      end
    end
  end

  describe '#save' do
    let(:client) { double }
    let(:uuid) { 'foo' }

    before do
      allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    end

    it 'stores request id and enqueues stats job' do
      expect_to_obtain_exclusive_lease(GitlabPerformanceBarStatsWorker::LEASE_KEY, uuid)
      expect(GitlabPerformanceBarStatsWorker).to receive(:perform_in).with(GitlabPerformanceBarStatsWorker::WORKER_DELAY, uuid)
      expect(client).to receive(:sadd).with(GitlabPerformanceBarStatsWorker::STATS_KEY, uuid)
      expect(client).to receive(:expire).with(GitlabPerformanceBarStatsWorker::STATS_KEY, GitlabPerformanceBarStatsWorker::STATS_KEY_EXPIRE)

      peek_adapter.new(client).save('foo')
    end

    context 'when performance_bar_stats is disabled' do
      before do
        stub_feature_flags(performance_bar_stats: false)
      end

      it 'ignores stats processing for the request' do
        expect(GitlabPerformanceBarStatsWorker).not_to receive(:perform_in)
        expect(client).not_to receive(:sadd)

        peek_adapter.new(client).save('foo')
      end
    end

    context 'when exclusive lease has been already taken' do
      before do
        stub_exclusive_lease_taken(GitlabPerformanceBarStatsWorker::LEASE_KEY)
      end

      it 'stores request id but does not enqueue any job' do
        expect(GitlabPerformanceBarStatsWorker).not_to receive(:perform_in)
        expect(client).to receive(:sadd).with(GitlabPerformanceBarStatsWorker::STATS_KEY, uuid)

        peek_adapter.new(client).save('foo')
      end
    end
  end
end
