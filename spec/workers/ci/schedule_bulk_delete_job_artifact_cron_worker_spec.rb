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

    it 'recovers stale buckets' do
      expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:recover_stale_buckets)

      worker.perform
    end

    it 'enqueues missing buckets with correct max_buckets' do
      expected_max = Ci::BulkDeleteExpiredJobArtifactsWorker.max_running_jobs_limit

      expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:enqueue_missing_buckets)
        .with(max_buckets: expected_max)

      worker.perform
    end

    it 'triggers bulk delete workers' do
      expect(Ci::BulkDeleteExpiredJobArtifactsWorker).to receive(:perform_with_capacity)

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
