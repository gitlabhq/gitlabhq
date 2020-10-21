# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DestroyExpiredJobArtifactsService, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  describe '.execute' do
    subject { service.execute }

    let(:service) { described_class.new }

    let_it_be(:artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

    before(:all) do
      artifact.job.pipeline.unlocked!
    end

    context 'when artifact is expired' do
      context 'when artifact is not locked' do
        before do
          artifact.job.pipeline.unlocked!
        end

        it 'destroys job artifact' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
        end
      end

      context 'when artifact is locked' do
        before do
          artifact.job.pipeline.artifacts_locked!
        end

        it 'does not destroy job artifact' do
          expect { subject }.not_to change { Ci::JobArtifact.count }
        end
      end
    end

    context 'when artifact is not expired' do
      before do
        artifact.update_column(:expire_at, 1.day.since)
      end

      it 'does not destroy expired job artifacts' do
        expect { subject }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when artifact is permanent' do
      before do
        artifact.update_column(:expire_at, nil)
      end

      it 'does not destroy expired job artifacts' do
        expect { subject }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when failed to destroy artifact' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_LIMIT', 10)

        allow_any_instance_of(Ci::JobArtifact)
          .to receive(:destroy!)
          .and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it 'raises an exception and stop destroying' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context 'when exclusive lease has already been taken by the other instance' do
      before do
        stub_exclusive_lease_taken(described_class::EXCLUSIVE_LOCK_KEY, timeout: described_class::LOCK_TIMEOUT)
      end

      it 'raises an error and does not start destroying' do
        expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end

    context 'when timeout happens' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_TIMEOUT', 1.second)
        allow_any_instance_of(described_class).to receive(:destroy_batch) { true }
      end

      it 'returns false and does not continue destroying' do
        is_expected.to be_falsy
      end
    end

    context 'when loop reached loop limit' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_LIMIT', 1)
        stub_const('Ci::DestroyExpiredJobArtifactsService::BATCH_SIZE', 1)

        second_artifact.job.pipeline.unlocked!
      end

      let!(:second_artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

      it 'raises an error and does not continue destroying' do
        is_expected.to be_falsy
      end

      it 'destroys one artifact' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      end
    end

    context 'when there are no artifacts' do
      before do
        artifact.destroy!
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when there are artifacts more than batch sizes' do
      before do
        stub_const('Ci::DestroyExpiredJobArtifactsService::BATCH_SIZE', 1)

        second_artifact.job.pipeline.unlocked!
      end

      let!(:second_artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

      it 'destroys all expired artifacts' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
      end
    end

    context 'when artifact is a pipeline artifact' do
      context 'when artifacts are expired' do
        let!(:pipeline_artifact_1) { create(:ci_pipeline_artifact, expire_at: 1.week.ago) }
        let!(:pipeline_artifact_2) { create(:ci_pipeline_artifact, expire_at: 1.week.ago) }

        before do
          [pipeline_artifact_1, pipeline_artifact_2].each { |pipeline_artifact| pipeline_artifact.pipeline.unlocked! }
        end

        it 'destroys pipeline artifacts' do
          expect { subject }.to change { Ci::PipelineArtifact.count }.by(-2)
        end
      end

      context 'when artifacts are not expired' do
        let!(:pipeline_artifact_1) { create(:ci_pipeline_artifact, expire_at: 2.days.from_now) }
        let!(:pipeline_artifact_2) { create(:ci_pipeline_artifact, expire_at: 2.days.from_now) }

        before do
          [pipeline_artifact_1, pipeline_artifact_2].each { |pipeline_artifact| pipeline_artifact.pipeline.unlocked! }
        end

        it 'does not destroy pipeline artifacts' do
          expect { subject }.not_to change { Ci::PipelineArtifact.count }
        end
      end
    end

    context 'when some artifacts are locked' do
      before do
        pipeline = create(:ci_pipeline, locked: :artifacts_locked)
        job = create(:ci_build, pipeline: pipeline)
        create(:ci_job_artifact, expire_at: 1.day.ago, job: job)
      end

      it 'destroys only unlocked artifacts' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      end
    end
  end
end
