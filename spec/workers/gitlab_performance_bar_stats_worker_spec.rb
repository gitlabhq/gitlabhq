# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabPerformanceBarStatsWorker do
  include ExclusiveLeaseHelpers

  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:redis) { double(Gitlab::Redis::SharedState) }
    let(:uuid) { 1 }

    before do
      expect(Gitlab::Redis::Cache).to receive(:with).and_yield(redis)
      expect_to_cancel_exclusive_lease(GitlabPerformanceBarStatsWorker::LEASE_KEY, uuid)
    end

    it 'fetches list of request ids and processes them' do
      expect(redis).to receive(:smembers).with(GitlabPerformanceBarStatsWorker::STATS_KEY).and_return([1, 2])
      expect(redis).to receive(:del).with(GitlabPerformanceBarStatsWorker::STATS_KEY)
      expect_next_instance_of(Gitlab::PerformanceBar::Stats) do |stats|
        expect(stats).to receive(:process).with(1)
        expect(stats).to receive(:process).with(2)
      end

      worker.perform(uuid)
    end
  end
end
