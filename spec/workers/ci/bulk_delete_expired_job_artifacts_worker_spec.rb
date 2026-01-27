# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BulkDeleteExpiredJobArtifactsWorker, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  it 'is a limited capacity worker' do
    expect(described_class.new).to be_a(LimitedCapacity::Worker)
  end

  describe '.max_running_jobs_limit' do
    it { expect(described_class.max_running_jobs_limit).to eq(10) }

    context 'when bulk_delete_job_artifacts_high_concurrency is disabled' do
      before do
        stub_feature_flags(bulk_delete_job_artifacts_high_concurrency: false)
      end

      it { expect(described_class.max_running_jobs_limit).to eq(5) }
    end
  end

  describe '#perform_work' do
    let(:bucket) { 0 }
    let(:max_running_jobs) { described_class.max_running_jobs_limit }

    context 'when bulk_delete_job_artifacts feature flag is disabled' do
      before do
        stub_feature_flags(bulk_delete_job_artifacts: false)
      end

      it 'returns early without claiming a bucket' do
        expect(Gitlab::Ci::Artifacts::BucketManager).not_to receive(:claim_bucket)
        worker.perform_work
      end
    end

    context 'when a bucket is claimed' do
      before do
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket).and_return(bucket)
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:release_bucket)
      end

      it 'claims a bucket from BucketManager' do
        expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, bucket)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:artifacts_empty, true)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, 0)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket_released, bucket)

        worker.perform_work
      end

      it 'releases the bucket after processing' do
        expect(Gitlab::Ci::Artifacts::BucketManager).to receive(:release_bucket)
          .with(bucket, max_buckets: max_running_jobs)
        allow(worker).to receive(:log_extra_metadata_on_done)
        worker.perform_work
      end

      context 'when there are expired artifacts' do
        let_it_be(:project) { create(:project) }
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

        let!(:artifact) do
          create(:ci_job_artifact, :archive,
            job: create(:ci_build, pipeline: pipeline),
            expire_at: 1.day.ago,
            locked: Ci::JobArtifact.lockeds[:unlocked])
        end

        before do
          # Ensure artifact matches the bucket filter
          allow(worker).to receive(:get_artifacts).and_return(
            Ci::JobArtifact.where(id: artifact.id),
            Ci::JobArtifact.none
          )
        end

        it 'destroys expired artifacts' do
          expect { worker.perform_work }.to change { Ci::JobArtifact.count }.by(-1)
        end

        it 'logs the destroyed count' do
          allow(worker).to receive(:log_extra_metadata_on_done)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, 1)
          worker.perform_work
        end
      end

      context 'when scale-down occurs during processing' do
        let(:bucket) { 7 }

        before do
          allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket).and_return(bucket)
        end

        it 'terminates early and logs scale-down' do
          # Simulate scale-down: bucket 7 is now invalid with max 5
          stub_feature_flags(bulk_delete_job_artifacts_high_concurrency: false)

          expect(worker).to receive(:log_extra_metadata_on_done).with(:terminated_early_due_to_scale_down, true)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, 0)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, bucket)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket_released, bucket)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:artifacts_empty, true)
          worker.perform_work
        end
      end
    end

    context 'when no bucket is available' do
      before do
        allow(Gitlab::Ci::Artifacts::BucketManager).to receive(:claim_bucket).and_return(nil)
      end

      it 'returns early without processing' do
        expect(Gitlab::Ci::Artifacts::BucketManager).not_to receive(:release_bucket)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:mod_bucket, nil)
        expect(worker).not_to receive(:get_artifacts)

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

    context 'when a bucket was claimed' do
      let(:bucket) { 0 }
      let(:max_running_jobs) { described_class.max_running_jobs_limit }

      before do
        worker.instance_variable_set(:@bucket_claimed, true)
        worker.instance_variable_set(:@mod_bucket, bucket)
      end

      context 'when there are expired artifacts matching the bucket MOD condition' do
        let_it_be(:project) { create(:project) }
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
        let_it_be(:job) { create(:ci_build, pipeline: pipeline) }
        let_it_be(:expired_artifact) do
          create(:ci_job_artifact, :archive,
            job: job,
            expire_at: 1.day.ago,
            locked: Ci::JobArtifact.lockeds[:unlocked])
        end

        it 'returns 999 when artifact matches bucket' do
          # Set bucket to match the artifact's (project_id + job_id) % max_running_jobs
          matching_bucket = (project.id + job.id) % max_running_jobs
          worker.instance_variable_set(:@mod_bucket, matching_bucket)

          expect(worker.remaining_work_count).to eq(999)
        end

        it 'returns 0 when artifact does not match bucket' do
          # Set bucket to a value that won't match
          matching_bucket = (project.id + job.id) % max_running_jobs
          non_matching_bucket = (matching_bucket + 1) % max_running_jobs
          worker.instance_variable_set(:@mod_bucket, non_matching_bucket)

          expect(worker.remaining_work_count).to eq(0)
        end
      end

      context 'when there are no expired artifacts' do
        it 'returns 0' do
          expect(worker.remaining_work_count).to eq(0)
        end
      end
    end
  end

  describe '#max_running_jobs' do
    it 'delegates to class method' do
      expect(worker.max_running_jobs).to eq(described_class.max_running_jobs_limit)
    end
  end
end
