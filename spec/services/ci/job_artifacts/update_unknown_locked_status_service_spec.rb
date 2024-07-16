# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::UpdateUnknownLockedStatusService, :clean_gitlab_redis_shared_state,
  feature_category: :job_artifacts do
  include ExclusiveLeaseHelpers

  let(:service) { described_class.new }

  describe '.execute' do
    subject { service.execute }

    let_it_be(:locked_pipeline) { create(:ci_pipeline, :artifacts_locked) }
    let_it_be(:pipeline) { create(:ci_pipeline, :unlocked) }
    let_it_be(:locked_job) { create(:ci_build, :success, pipeline: locked_pipeline) }
    let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline) }

    let!(:unknown_unlocked_artifact) do
      create(:ci_job_artifact, :junit, expire_at: 1.hour.ago, job: job, locked: Ci::JobArtifact.lockeds[:unknown])
    end

    let!(:unknown_locked_artifact) do
      create(:ci_job_artifact, :lsif,
        expire_at: 1.day.ago,
        job: locked_job,
        locked: Ci::JobArtifact.lockeds[:unknown]
      )
    end

    let!(:unlocked_artifact) do
      create(:ci_job_artifact, :archive, expire_at: 1.hour.ago, job: job, locked: Ci::JobArtifact.lockeds[:unlocked])
    end

    let!(:locked_artifact) do
      create(:ci_job_artifact, :sast, :raw,
        expire_at: 1.day.ago,
        job: locked_job,
        locked: Ci::JobArtifact.lockeds[:artifacts_locked]
      )
    end

    context 'when artifacts are expired' do
      it 'sets artifact_locked when the pipeline is locked' do
        expect { service.execute }
          .to change { unknown_locked_artifact.reload.locked }.from('unknown').to('artifacts_locked')
          .and not_change { Ci::JobArtifact.exists?(locked_artifact.id) }
      end

      it 'destroys the artifact when the pipeline is unlocked' do
        expect { subject }.to change { Ci::JobArtifact.exists?(unknown_unlocked_artifact.id) }.from(true).to(false)
      end

      it 'does not update ci_job_artifact rows with known locked values' do
        expect { service.execute }
          .to not_change(locked_artifact, :attributes)
          .and not_change { Ci::JobArtifact.exists?(locked_artifact.id) }
          .and not_change(unlocked_artifact, :attributes)
          .and not_change { Ci::JobArtifact.exists?(unlocked_artifact.id) }
      end

      it 'logs the counts of affected artifacts' do
        expect(subject).to eq({ removed: 1, locked: 1 })
      end
    end

    context 'in a single iteration' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      context 'due to the LOOP_TIMEOUT' do
        before do
          stub_const("#{described_class}::LOOP_TIMEOUT", 0.seconds)
        end

        it 'affects the earliest expired artifact first' do
          subject

          expect(unknown_locked_artifact.reload.locked).to eq('artifacts_locked')
          expect(unknown_unlocked_artifact.reload.locked).to eq('unknown')
        end

        it 'reports the number of destroyed artifacts' do
          is_expected.to eq({ removed: 0, locked: 1 })
        end
      end

      context 'due to @loop_limit' do
        context 'when feature flag ci_job_artifacts_backlog_large_loop_limit is enabled' do
          before do
            stub_const("#{described_class}::LARGE_LOOP_LIMIT", 1)
          end

          it 'affects the most recently expired artifact first' do
            subject

            expect(unknown_locked_artifact.reload.locked).to eq('artifacts_locked')
            expect(unknown_unlocked_artifact.reload.locked).to eq('unknown')
          end

          it 'reports the number of destroyed artifacts' do
            is_expected.to eq({ removed: 0, locked: 1 })
          end
        end

        context 'when feature flag ci_job_artifacts_backlog_large_loop_limit is disabled' do
          before do
            stub_feature_flags(ci_job_artifacts_backlog_large_loop_limit: false)
            stub_const("#{described_class}::LOOP_LIMIT", 1)
          end

          it 'affects the most recently expired artifact first' do
            subject

            expect(unknown_locked_artifact.reload.locked).to eq('artifacts_locked')
            expect(unknown_unlocked_artifact.reload.locked).to eq('unknown')
          end

          it 'reports the number of destroyed artifacts' do
            is_expected.to eq({ removed: 0, locked: 1 })
          end
        end
      end
    end

    context 'when artifact is not expired' do
      let!(:unknown_unlocked_artifact) do
        create(:ci_job_artifact, :junit,
          expire_at: 1.year.from_now,
          job: job,
          locked: Ci::JobArtifact.lockeds[:unknown]
        )
      end

      it 'does not change the locked status' do
        expect { service.execute }.not_to change { unknown_unlocked_artifact.locked }
        expect(Ci::JobArtifact.exists?(unknown_unlocked_artifact.id)).to eq(true)
      end
    end

    context 'when exclusive lease has already been taken by the other instance' do
      before do
        stub_exclusive_lease_taken(described_class::EXCLUSIVE_LOCK_KEY, timeout: described_class::LOCK_TIMEOUT)
      end

      it 'raises an error and' do
        expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end

    context 'when there are no unknown status artifacts' do
      before do
        Ci::JobArtifact.update_all(locked: :unlocked)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq({ removed: 0, locked: 0 })
      end
    end
  end
end
