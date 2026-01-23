# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::StaleRequestsCleanupCronWorker,
  :clean_gitlab_redis_rate_limiting, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:service) { Gitlab::TopologyServiceClient::ConcurrencyLimitService }

  describe 'worker configuration' do
    it 'has correct feature category' do
      expect(described_class.get_feature_category).to eq(:cell)
    end

    it 'has low urgency' do
      expect(described_class.get_urgency).to eq(:low)
    end

    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end
  end

  describe '#perform' do
    it 'calls cleanup_stale_requests on the service' do
      expect(service).to receive(:cleanup_stale_requests).and_return({ removed_count: 0 })

      worker.perform
    end

    context 'when there are no stale requests' do
      before do
        allow(service).to receive(:cleanup_stale_requests).and_return({ removed_count: 0 })
      end

      it 'logs zero removed count' do
        worker.perform
        expect(worker.logging_extras).to include(
          'extra.cells_stale_requests_cleanup_cron_worker.removed_count' => 0
        )
      end
    end

    context 'when there are stale requests' do
      before do
        allow(service).to receive(:cleanup_stale_requests).and_return({ removed_count: 5 })
      end

      it 'logs the number of stale requests removed' do
        worker.perform
        expect(worker.logging_extras).to include(
          'extra.cells_stale_requests_cleanup_cron_worker.removed_count' => 5
        )
      end
    end

    context 'when there are many stale requests' do
      before do
        allow(service).to receive(:cleanup_stale_requests).and_return({ removed_count: 100 })
      end

      it 'logs the correct count' do
        worker.perform
        expect(worker.logging_extras).to include(
          'extra.cells_stale_requests_cleanup_cron_worker.removed_count' => 100
        )
      end
    end
  end

  it_behaves_like 'an idempotent worker'
end
