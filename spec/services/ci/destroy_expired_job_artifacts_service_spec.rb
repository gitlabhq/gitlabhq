# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DestroyExpiredJobArtifactsService, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let(:service) { described_class.new }

  describe '.execute' do
    subject { service.execute }

    let_it_be(:artifact, reload: true) do
      create(:ci_job_artifact, expire_at: 1.day.ago)
    end

    before(:all) do
      artifact.job.pipeline.unlocked!
    end

    context 'when artifact is expired' do
      context 'with preloaded relationships' do
        before do
          job = create(:ci_build, pipeline: artifact.job.pipeline)
          create(:ci_job_artifact, :archive, :expired, job: job)

          stub_const('Ci::DestroyExpiredJobArtifactsService::LOOP_LIMIT', 1)
        end

        it 'performs the smallest number of queries for job_artifacts' do
          log = ActiveRecord::QueryRecorder.new { subject }

          # SELECT expired ci_job_artifacts
          # PRELOAD projects, routes, project_statistics
          # BEGIN
          # INSERT into ci_deleted_objects
          # DELETE loaded ci_job_artifacts
          # DELETE security_findings  -- for EE
          # COMMIT
          expect(log.count).to be_within(1).of(8)
        end
      end

      context 'when artifact is not locked' do
        it 'deletes job artifact record' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
        end

        context 'when the artifact does not a file attached to it' do
          it 'does not create deleted objects' do
            expect(artifact.exists?).to be_falsy # sanity check

            expect { subject }.not_to change { Ci::DeletedObject.count }
          end
        end

        context 'when the artifact has a file attached to it' do
          before do
            artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
            artifact.save!
          end

          it 'creates a deleted object' do
            expect { subject }.to change { Ci::DeletedObject.count }.by(1)
          end

          it 'resets project statistics' do
            expect(ProjectStatistics).to receive(:increment_statistic).once
              .with(artifact.project, :build_artifacts_size, -artifact.file.size)
              .and_call_original

            subject
          end

          it 'does not remove the files' do
            expect { subject }.not_to change { artifact.file.exists? }
          end

          it 'reports metrics for destroyed artifacts' do
            counter = service.send(:destroyed_artifacts_counter)

            expect(counter).to receive(:increment).with({}, 1).and_call_original

            subject
          end
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
      end

      context 'when the import fails' do
        before do
          expect(Ci::DeletedObject)
            .to receive(:bulk_import)
            .once
            .and_raise(ActiveRecord::RecordNotDestroyed)
        end

        it 'raises an exception and stop destroying' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotDestroyed)
                            .and not_change { Ci::JobArtifact.count }.from(1)
        end
      end

      context 'when the delete fails' do
        before do
          expect(Ci::JobArtifact)
            .to receive(:id_in)
            .once
            .and_raise(ActiveRecord::RecordNotDestroyed)
        end

        it 'raises an exception rolls back the insert' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotDestroyed)
                            .and not_change { Ci::DeletedObject.count }.from(0)
        end
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
        allow_any_instance_of(described_class).to receive(:destroy_artifacts_batch) { true }
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

  describe '.destroy_job_artifacts_batch' do
    it 'returns a falsy value without artifacts' do
      expect(service.send(:destroy_job_artifacts_batch)).to be_falsy
    end
  end

  describe '.destroy_pipeline_artifacts_batch' do
    it 'returns a falsy value without artifacts' do
      expect(service.send(:destroy_pipeline_artifacts_batch)).to be_falsy
    end
  end
end
