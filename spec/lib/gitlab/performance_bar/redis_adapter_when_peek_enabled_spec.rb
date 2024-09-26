# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled, feature_category: :observability do
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
      expect(client).to receive(:exists?).with(GitlabPerformanceBarStatsWorker::STATS_KEY).and_return(false)
      expect(client).to receive(:sadd?).with(GitlabPerformanceBarStatsWorker::STATS_KEY, uuid)
      expect(client).to receive(:expire).with(GitlabPerformanceBarStatsWorker::STATS_KEY, GitlabPerformanceBarStatsWorker::STATS_KEY_EXPIRE)

      peek_adapter.new(client).save('foo')
    end

    context 'when performance_bar_stats is disabled' do
      before do
        stub_feature_flags(performance_bar_stats: false)
      end

      it 'ignores stats processing for the request' do
        expect(client).not_to receive(:sadd)

        peek_adapter.new(client).save('foo')
      end
    end
  end
end
