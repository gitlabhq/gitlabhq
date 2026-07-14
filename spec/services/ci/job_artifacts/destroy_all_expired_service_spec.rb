# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyAllExpiredService, feature_category: :job_artifacts do
  let(:service) { described_class.new(mod_bucket: 0, max_buckets: 1) }

  describe '#execute' do
    subject(:result) { service.execute }

    let_it_be(:locked_pipeline) { create(:ci_pipeline, :artifacts_locked) }
    let_it_be(:pipeline) { create(:ci_pipeline, :unlocked) }
    let_it_be(:locked_job) { create(:ci_build, :success, pipeline: locked_pipeline) }
    let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline) }

    context 'when artifact is expired' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }

      context 'with preloaded relationships' do
        let(:second_artifact) { create(:ci_job_artifact, :expired, :junit, job: job) }

        let(:more_artifacts) do
          [
            create(:ci_job_artifact, :expired, :sast, job: job),
            create(:ci_job_artifact, :expired, :metadata, job: job),
            create(:ci_job_artifact, :expired, :codequality, job: job),
            create(:ci_job_artifact, :expired, :accessibility, job: job)
          ]
        end

        before do
          stub_const("#{described_class}::LOOP_LIMIT", 1)

          # This artifact-with-file is created before the control execution to ensure
          # that the DeletedObject operations are accounted for in the query count.
          second_artifact
        end

        it 'performs a consistent number of queries' do
          control = ActiveRecord::QueryRecorder.new { described_class.new(mod_bucket: 0, max_buckets: 1).execute }

          more_artifacts

          expect { described_class.new(mod_bucket: 0, max_buckets: 1).execute }.not_to exceed_query_limit(control)
        end
      end

      context 'when artifact is not locked' do
        it 'deletes the job artifact record' do
          expect { result }.to change { Ci::JobArtifact.count }.by(-1)
        end

        it 'returns a Result with the destroyed count' do
          expect(result.destroyed_count).to eq(1)
        end

        context 'when the artifact does not have a file attached to it' do
          it 'does not create deleted objects' do
            expect(artifact.exists?).to be_falsy # sanity check

            expect { result }.not_to change { Ci::DeletedObject.count }
          end
        end

        context 'when the artifact has a file attached to it' do
          let!(:artifact) { create(:ci_job_artifact, :expired, :zip, job: job, locked: job.pipeline.locked) }

          it 'creates a deleted object' do
            expect { result }.to change { Ci::DeletedObject.count }.by(1)
          end

          it 'resets project statistics', :sidekiq_inline do
            expect { result }
              .to change { artifact.project.statistics.reload.build_artifacts_size }.by(-artifact.file.size)
          end

          it 'does not remove the files' do
            expect { result }.not_to change { artifact.file.exists? }
          end
        end

        context 'when the project in which the artifact belongs to is undergoing stats refresh' do
          before do
            create(:project_build_artifacts_size_refresh, :pending, project: artifact.project)
          end

          it 'does not destroy the job artifact' do
            expect { result }.not_to change { Ci::JobArtifact.count }
          end
        end
      end

      context 'when artifact is locked' do
        let!(:artifact) { create(:ci_job_artifact, :expired, job: locked_job, locked: locked_job.pipeline.locked) }

        it 'does not destroy the job artifact' do
          expect { result }.not_to change { Ci::JobArtifact.count }
        end
      end
    end

    context 'when artifact is not expired' do
      let!(:artifact) { create(:ci_job_artifact, job: job, locked: job.pipeline.locked) }

      it 'does not destroy expired job artifacts' do
        expect { result }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when artifact is permanent' do
      let!(:artifact) { create(:ci_job_artifact, expire_at: nil, job: job, locked: job.pipeline.locked) }

      it 'does not destroy expired job artifacts' do
        expect { result }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when failed to destroy artifact' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }

      before do
        stub_const("#{described_class}::LOOP_LIMIT", 10)
      end

      context 'when the import fails' do
        before do
          expect(Ci::DeletedObject)
            .to receive(:bulk_import)
            .once
            .and_raise(ActiveRecord::RecordNotDestroyed)
        end

        it 'raises an exception and stops destroying' do
          expect { result }.to raise_error(ActiveRecord::RecordNotDestroyed)
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

        it 'raises an exception and rolls back the insert' do
          expect { result }.to raise_error(ActiveRecord::RecordNotDestroyed)
                           .and not_change { Ci::DeletedObject.count }.from(0)
        end
      end
    end

    context 'with a second artifact and batch size of 1' do
      let_it_be(:second_job) { create(:ci_build, :success, pipeline: pipeline) }
      let!(:second_artifact) do
        create(:ci_job_artifact, :archive, expire_at: 1.day.ago, job: second_job, locked: job.pipeline.locked)
      end

      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }

      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      context 'when timeout happens' do
        before do
          stub_const("#{described_class}::LOOP_TIMEOUT", 0.seconds)
        end

        it 'destroys one artifact' do
          expect { result }.to change { Ci::JobArtifact.count }.by(-1)
        end

        it 'reports the number of destroyed artifacts' do
          expect(result.destroyed_count).to eq(1)
        end
      end

      context 'when loop reaches the loop limit' do
        before do
          stub_const("#{described_class}::LOOP_LIMIT", 1)
        end

        it 'destroys one artifact' do
          expect { result }.to change { Ci::JobArtifact.count }.by(-1)
        end

        it 'reports the number of destroyed artifacts' do
          expect(result.destroyed_count).to eq(1)
        end
      end

      context 'when the number of artifacts is greater than the batch size' do
        it 'destroys all expired artifacts' do
          expect { result }.to change { Ci::JobArtifact.count }.by(-2)
        end

        it 'reports the number of destroyed artifacts' do
          expect(result.destroyed_count).to eq(2)
        end

        it 'signals that more work is likely (destroyed_count > BATCH_SIZE)' do
          expect(result.more_work_likely).to be(true)
        end
      end
    end

    context 'when there are no artifacts' do
      it 'does not raise an error' do
        expect { result }.not_to raise_error
      end

      it 'reports zero destroyed artifacts' do
        expect(result.destroyed_count).to eq(0)
      end

      it 'does not signal that more work is likely' do
        expect(result.more_work_likely).to be(false)
      end

      it 'exits early once all partitions are exhausted' do
        expect(result.exited_early).to be(true)
        expect(result.drain_loops).to eq(0)
        expect(result.partitions_exhausted).to be > 0
      end
    end

    context 'when some artifacts are locked' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:locked_artifact) do
        create(:ci_job_artifact, :expired, job: locked_job, locked: locked_job.pipeline.locked)
      end

      it 'destroys only unlocked artifacts' do
        expect { result }.to change { Ci::JobArtifact.count }.by(-1)
        expect(locked_artifact).to be_persisted
      end
    end

    context 'when some artifacts are trace' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:trace_artifact) { create(:ci_job_artifact, :trace, :expired, job: job, locked: job.pipeline.locked) }

      it 'destroys only non-trace artifacts' do
        expect { result }.to change { Ci::JobArtifact.count }.by(-1)
        expect(trace_artifact).to be_persisted
      end
    end

    context 'when all artifacts are locked' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: locked_job, locked: locked_job.pipeline.locked) }

      it 'destroys no artifacts' do
        expect { result }.to not_change { Ci::JobArtifact.count }
      end
    end

    context 'when the mod_bucket does not match any artifact' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }

      # Use modulus 2 with bucket 1, and an artifact whose (project_id + job_id) is even
      let(:service) do
        described_class.new(
          mod_bucket: ((artifact.project_id + artifact.job_id) + 1) % 2,
          max_buckets: 2
        )
      end

      it 'does not destroy artifacts that fall into other buckets' do
        expect { result }.not_to change { Ci::JobArtifact.count }
      end
    end

    context 'when expired artifacts span multiple partitions' do
      let_it_be(:pipeline_100) { create(:ci_pipeline, :unlocked, partition_id: 100) }
      let_it_be(:pipeline_102) { create(:ci_pipeline, :unlocked, partition_id: 102) }
      let_it_be(:job_100) { create(:ci_build, :success, pipeline: pipeline_100) }
      let_it_be(:job_102) { create(:ci_build, :success, pipeline: pipeline_102) }

      let!(:artifact_100) { create(:ci_job_artifact, :expired, job: job_100, locked: pipeline_100.locked) }
      let!(:artifact_101) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:artifact_102) { create(:ci_job_artifact, :expired, job: job_102, locked: pipeline_102.locked) }

      it 'destroys artifacts across all partitions' do
        expect { result }.to change { Ci::JobArtifact.count }.by(-3)
        expect(result.destroyed_count).to eq(3)
      end

      it 'tracks drain loops, exhausted partitions, and an early exit' do
        expect(result.drain_loops).to be > 0
        expect(result.partitions_exhausted).to be > 0
        expect(result.exited_early).to be(true)
      end
    end

    context 'when the loop reaches LOOP_LIMIT before exhausting partitions' do
      let_it_be(:pipeline_100) { create(:ci_pipeline, :unlocked, partition_id: 100) }
      let_it_be(:job_100) { create(:ci_build, :success, pipeline: pipeline_100) }
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job_100, locked: pipeline_100.locked) }

      before do
        stub_const("#{described_class}::LOOP_LIMIT", 1)
      end

      it 'does not signal an early exit' do
        expect(result.exited_early).to be(false)
      end
    end

    context 'when the destroyed count exceeds BATCH_SIZE' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      let_it_be(:second_job) { create(:ci_build, :success, pipeline: pipeline) }
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }
      let!(:second_artifact) do
        create(:ci_job_artifact, :expired, job: second_job, locked: second_job.pipeline.locked)
      end

      it 'signals more work is likely' do
        expect(result.more_work_likely).to be(true)
      end
    end

    context 'when the destroyed count does not exceed BATCH_SIZE' do
      let!(:artifact) { create(:ci_job_artifact, :expired, job: job, locked: job.pipeline.locked) }

      it 'does not signal that more work is likely' do
        expect(result.destroyed_count).to eq(1)
        expect(result.more_work_likely).to be(false)
      end
    end
  end
end
