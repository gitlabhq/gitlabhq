# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyBatchService do
  let(:artifacts) { Ci::JobArtifact.where(id: [artifact_with_file.id, artifact_without_file.id]) }
  let(:service) { described_class.new(artifacts, pick_up_at: Time.current) }

  let_it_be(:artifact_with_file, refind: true) do
    create(:ci_job_artifact, :zip)
  end

  let_it_be(:artifact_without_file, refind: true) do
    create(:ci_job_artifact)
  end

  let_it_be(:undeleted_artifact, refind: true) do
    create(:ci_job_artifact)
  end

  describe '.execute' do
    subject(:execute) { service.execute }

    it 'creates a deleted object for artifact with attached file' do
      expect { subject }.to change { Ci::DeletedObject.count }.by(1)
    end

    it 'does not remove the attached file' do
      expect { execute }.not_to change { artifact_with_file.file.exists? }
    end

    it 'deletes the artifact records' do
      expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
    end

    it 'reports metrics for destroyed artifacts' do
      expect_next_instance_of(Gitlab::Ci::Artifacts::Metrics) do |metrics|
        expect(metrics).to receive(:increment_destroyed_artifacts_count).with(2).and_call_original
        expect(metrics).to receive(:increment_destroyed_artifacts_bytes).with(107464).and_call_original
      end

      execute
    end

    context 'ProjectStatistics' do
      it 'resets project statistics' do
        expect(ProjectStatistics).to receive(:increment_statistic).once
          .with(artifact_with_file.project, :build_artifacts_size, -artifact_with_file.file.size)
          .and_call_original
        expect(ProjectStatistics).to receive(:increment_statistic).once
          .with(artifact_without_file.project, :build_artifacts_size, 0)
          .and_call_original

        execute
      end

      context 'with update_stats: false' do
        it 'does not update project statistics' do
          expect(ProjectStatistics).not_to receive(:increment_statistic)

          service.execute(update_stats: false)
        end

        it 'returns size statistics' do
          expected_updates = {
            statistics_updates: {
              artifact_with_file.project => -artifact_with_file.file.size,
              artifact_without_file.project => 0
            }
          }

          expect(service.execute(update_stats: false)).to match(
            a_hash_including(expected_updates))
        end
      end
    end

    context 'when failed to destroy artifact' do
      context 'when the import fails' do
        before do
          expect(Ci::DeletedObject)
            .to receive(:bulk_import)
            .once
            .and_raise(ActiveRecord::RecordNotDestroyed)
        end

        it 'raises an exception and stop destroying' do
          expect { execute }.to raise_error(ActiveRecord::RecordNotDestroyed)
                            .and not_change { Ci::JobArtifact.count }
        end
      end
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { execute }.not_to raise_error
      end

      it 'reports the number of destroyed artifacts' do
        is_expected.to eq(destroyed_artifacts_count: 0, statistics_updates: {}, status: :success)
      end
    end

    context 'with artifacts that has backfilled expire_at' do
      let!(:created_on_00_30_45_minutes_on_21_22_23) do
        [
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-21 00:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-21 01:30:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-22 12:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-22 12:30:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-23 23:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-23 23:30:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-23 06:45:00.000'))
        ]
      end

      let!(:created_close_to_00_or_30_minutes) do
        [
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-21 00:00:00.001')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-21 00:30:00.999'))
        ]
      end

      let!(:created_on_00_or_30_minutes_on_other_dates) do
        [
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-01 00:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-19 12:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-24 23:30:00.000'))
        ]
      end

      let!(:created_at_other_times) do
        [
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-19 00:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-19 00:30:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-24 00:00:00.000')),
          create(:ci_job_artifact, expire_at: Time.zone.parse('2022-01-24 00:30:00.000'))
        ]
      end

      let(:artifacts_to_keep) { created_on_00_30_45_minutes_on_21_22_23 }
      let(:artifacts_to_delete) { created_close_to_00_or_30_minutes + created_on_00_or_30_minutes_on_other_dates + created_at_other_times }
      let(:all_artifacts) { artifacts_to_keep + artifacts_to_delete }

      let(:artifacts) { Ci::JobArtifact.where(id: all_artifacts.map(&:id)) }

      it 'deletes job artifacts that do not have expire_at on 00, 30 or 45 minute of 21, 22, 23 of the month' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(artifacts_to_delete.size * -1)
      end

      it 'keeps job artifacts that have expire_at on 00, 30 or 45 minute of 21, 22, 23 of the month' do
        expect { subject }.not_to change { Ci::JobArtifact.where(id: artifacts_to_keep.map(&:id)).count }
      end

      it 'removes expire_at on job artifacts that have expire_at on 00, 30 or 45 minute of 21, 22, 23 of the month' do
        subject

        expect(artifacts_to_keep.all? { |artifact| artifact.reload.expire_at.nil? }).to be(true)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ci_detect_wrongly_expired_artifacts: false)
        end

        it 'deletes all job artifacts' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(all_artifacts.size * -1)
        end
      end

      context 'when fix_expire_at is false' do
        let(:service) { described_class.new(artifacts, pick_up_at: Time.current, fix_expire_at: false) }

        it 'deletes all job artifacts' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(all_artifacts.size * -1)
        end
      end
    end
  end
end
