# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BulkDeleteExpiredJobArtifactsWorker, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  it 'is a limited capacity worker' do
    expect(described_class.new).to be_a(LimitedCapacity::Worker)
  end

  describe '.max_running_jobs_limit' do
    it { expect(described_class.max_running_jobs_limit).to eq(5) }
  end

  describe '#perform_work' do
    let(:max_running_jobs) { described_class.max_running_jobs_limit }
    let(:bucket) { 0 }
    let(:service) { instance_double(Ci::JobArtifacts::DestroyAllExpiredService, execute: result) }
    let(:result) do
      Ci::JobArtifacts::DestroyAllExpiredService::Result.new(
        destroyed_count: destroyed_count,
        more_work_likely: more_work_likely,
        drain_loops: drain_loops,
        partitions_exhausted: partitions_exhausted,
        exited_early: exited_early
      )
    end

    let(:destroyed_count) { 7 }
    let(:more_work_likely) { false }
    let(:drain_loops) { 3 }
    let(:partitions_exhausted) { 2 }
    let(:exited_early) { true }

    context 'when a bucket is claimed' do
      before do
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket).and_return(bucket)
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:release_bucket)
        allow(Ci::JobArtifacts::DestroyAllExpiredService).to receive(:new).and_return(service)
      end

      it 'delegates deletion to DestroyAllExpiredService with the claimed bucket' do
        expect(Ci::JobArtifacts::DestroyAllExpiredService)
          .to receive(:new).with(mod_bucket: bucket, max_buckets: max_running_jobs)
          .and_return(service)

        worker.perform_work
      end

      it 'logs the destroyed count, partition metrics, and bucket metadata' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, bucket)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:drain_loops, drain_loops)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:partitions_exhausted, partitions_exhausted)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:exited_early, exited_early)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, destroyed_count)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket_released, bucket)

        worker.perform_work
      end

      it 'releases the bucket after processing' do
        expect(Gitlab::Ci::Artifacts::BucketManager)
          .to receive(:release_bucket).with(bucket, max_buckets: max_running_jobs)

        worker.perform_work
      end

      context 'when the service signals more work is likely' do
        let(:more_work_likely) { true }

        it 'reports 999 remaining work to trigger re-enqueue' do
          worker.perform_work

          expect(worker.remaining_work_count).to eq(999)
        end
      end

      context 'when the service signals no more work is likely' do
        let(:more_work_likely) { false }

        it 'reports 0 remaining work' do
          worker.perform_work

          expect(worker.remaining_work_count).to eq(0)
        end
      end

      context 'when scale-down occurs and the claimed bucket is out of range' do
        let(:bucket) { max_running_jobs + 2 }

        it 'terminates early, logs scale-down, and does not call the service' do
          expect(Ci::JobArtifacts::DestroyAllExpiredService).not_to receive(:new)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, bucket)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:terminated_early_due_to_scale_down, true)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, 0)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket_released, bucket)

          worker.perform_work
        end

        it 'reports 0 remaining work even after scale-down termination' do
          worker.perform_work

          expect(worker.remaining_work_count).to eq(0)
        end
      end
    end

    context 'when no bucket is available' do
      before do
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket).and_return(nil)
      end

      it 'returns early without processing or releasing a bucket' do
        expect(Ci::JobArtifacts::DestroyAllExpiredService).not_to receive(:new)
        expect(Gitlab::Ci::Artifacts::BucketManager).not_to receive(:release_bucket)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, nil)

        worker.perform_work
      end
    end
  end

  describe '#remaining_work_count' do
    context 'when no bucket was claimed' do
      it 'returns 0' do
        expect(worker.remaining_work_count).to eq(0)
      end
    end
  end

  describe '#max_running_jobs' do
    it 'delegates to the class method' do
      expect(worker.max_running_jobs).to eq(described_class.max_running_jobs_limit)
    end
  end
end
