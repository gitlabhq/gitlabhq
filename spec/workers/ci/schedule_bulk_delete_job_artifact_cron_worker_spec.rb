# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ScheduleBulkDeleteJobArtifactCronWorker, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  it { is_expected.to include_module(CronjobQueue) }
  it { expect(described_class.idempotent?).to be_truthy }

  describe '#perform' do
    context 'when bulk_delete_job_artifacts feature flag is disabled' do
      before do
        stub_feature_flags(bulk_delete_job_artifacts: false)
      end

      it 'does not call BucketManager or trigger child workers' do
        expect(Gitlab::Ci::Artifacts::BucketManager).not_to receive(:recover_stale_buckets)
        expect(Gitlab::Ci::Artifacts::BucketManager).not_to receive(:enqueue_missing_buckets)
        expect(Ci::BulkDeleteExpiredJobArtifactsWorker).not_to receive(:perform_with_capacity)

        worker.perform
      end
    end

    context 'when bulk_delete_job_artifacts feature flag is enabled' do
      let(:max_buckets) { 10 }
      let(:stale_buckets) { instance_double(Array, count: 2) }
      let(:active_buckets) do
        {
          available: [1, 2],
          occupied: [3, 4, 5],
          missing: [6]
        }
      end

      before do
        stub_feature_flags(bulk_delete_job_artifacts: true)

        allow(Gitlab::Ci::Artifacts::BucketManager).to receive_messages(
          recover_stale_buckets: stale_buckets,
          enqueue_missing_buckets: active_buckets
        )

        allow(Ci::BulkDeleteExpiredJobArtifactsWorker).to receive(:perform_with_capacity)
      end

      it 'recovers stale buckets' do
        expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:recover_stale_buckets)
        worker.perform
      end

      it 'enqueues missing buckets with correct max_buckets' do
        expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:enqueue_missing_buckets)
          .with(max_buckets: max_buckets)
        worker.perform
      end

      it 'triggers bulk delete workers' do
        expect(Ci::BulkDeleteExpiredJobArtifactsWorker).to receive(:perform_with_capacity)
        worker.perform
      end

      it 'logs hash metadata on done with correct counts' do
        expect(worker).to receive(:log_hash_metadata_on_done).with(
          max_buckets: max_buckets,
          available_count: active_buckets[:available].count,
          occupied_count: active_buckets[:occupied].count,
          stale_count: stale_buckets.count,
          missing_count: active_buckets[:missing].count
        )

        worker.perform
      end

      context 'with high concurrency disabled' do
        before do
          stub_feature_flags(bulk_delete_job_artifacts_high_concurrency: false)
        end

        it 'enqueues missing buckets with decreased max_buckets' do
          expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:enqueue_missing_buckets)
            .with(max_buckets: 5)
          worker.perform
        end
      end
    end
  end
end
