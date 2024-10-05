# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyBatchService, feature_category: :job_artifacts do
  let(:artifacts) { Ci::JobArtifact.where(id: [artifact_with_file.id, artifact_without_file.id]) }
  let(:skip_projects_on_refresh) { false }
  let(:service) do
    described_class.new(
      artifacts,
      pick_up_at: Time.current,
      skip_projects_on_refresh: skip_projects_on_refresh
    )
  end

  let_it_be(:artifact_with_file, refind: true) do
    create(:ci_job_artifact, :zip)
  end

  let_it_be(:artifact_without_file, refind: true) do
    create(:ci_job_artifact)
  end

  let_it_be(:undeleted_artifact, refind: true) do
    create(:ci_job_artifact)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'creates a deleted object for artifact with attached file' do
      expect { subject }.to change { Ci::DeletedObject.count }.by(1)
    end

    it 'does not remove the attached file' do
      expect { execute }.not_to change { artifact_with_file.file.exists? }
    end

    it 'deletes the artifact records and logs them' do
      expect(Gitlab::Ci::Artifacts::Logger)
        .to receive(:log_deleted)
        .with(
          match_array([artifact_with_file, artifact_without_file]),
          'Ci::JobArtifacts::DestroyBatchService#execute'
        )

      expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
    end

    it 'reports metrics for destroyed artifacts' do
      expect_next_instance_of(Gitlab::Ci::Artifacts::Metrics) do |metrics|
        expect(metrics).to receive(:increment_destroyed_artifacts_count).with(2).and_call_original
        expect(metrics).to receive(:increment_destroyed_artifacts_bytes).with(ci_artifact_fixture_size).and_call_original
      end

      execute
    end

    context 'when artifact belongs to a project that is undergoing stats refresh' do
      let!(:artifact_under_refresh_1) do
        create(:ci_job_artifact, :zip)
      end

      let!(:artifact_under_refresh_2) do
        create(:ci_job_artifact, :zip)
      end

      let!(:artifact_under_refresh_3) do
        create(:ci_job_artifact, :zip, project: artifact_under_refresh_2.project)
      end

      let(:artifacts) do
        Ci::JobArtifact.where(id: [artifact_with_file.id, artifact_under_refresh_1.id, artifact_under_refresh_2.id,
          artifact_under_refresh_3.id])
      end

      before do
        create(:project_build_artifacts_size_refresh, :created, project: artifact_with_file.project)
        create(:project_build_artifacts_size_refresh, :pending, project: artifact_under_refresh_1.project)
        create(:project_build_artifacts_size_refresh, :running, project: artifact_under_refresh_2.project)
      end

      shared_examples 'avoiding N+1 queries' do
        let!(:control_artifact_on_refresh) do
          create(:ci_job_artifact, :zip)
        end

        let!(:control_artifact_non_refresh) do
          create(:ci_job_artifact, :zip)
        end

        let!(:other_artifact_on_refresh) do
          create(:ci_job_artifact, :zip)
        end

        let!(:other_artifact_on_refresh_2) do
          create(:ci_job_artifact, :zip)
        end

        let!(:other_artifact_non_refresh) do
          create(:ci_job_artifact, :zip)
        end

        let!(:control_artifacts) do
          Ci::JobArtifact.where(
            id: [
              control_artifact_on_refresh.id,
              control_artifact_non_refresh.id
            ]
          )
        end

        let!(:artifacts) do
          Ci::JobArtifact.where(
            id: [
              other_artifact_on_refresh.id,
              other_artifact_on_refresh_2.id,
              other_artifact_non_refresh.id
            ]
          )
        end

        let(:control_service) do
          described_class.new(
            control_artifacts,
            pick_up_at: Time.current,
            skip_projects_on_refresh: skip_projects_on_refresh
          )
        end

        before do
          create(:project_build_artifacts_size_refresh, :pending, project: control_artifact_on_refresh.project)
          create(:project_build_artifacts_size_refresh, :pending, project: other_artifact_on_refresh.project)
          create(:project_build_artifacts_size_refresh, :pending, project: other_artifact_on_refresh_2.project)
        end

        it 'does not make multiple queries when fetching multiple project refresh records' do
          control = ActiveRecord::QueryRecorder.new { control_service.execute }

          expect { subject }.not_to exceed_query_limit(control)
        end
      end

      context 'and skip_projects_on_refresh is set to false (default)' do
        it 'logs the projects undergoing refresh and continues with the delete', :aggregate_failures do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger).to receive(:warn_artifact_deletion_during_stats_refresh).with(
            method: 'Ci::JobArtifacts::DestroyBatchService#execute',
            project_id: artifact_under_refresh_1.project.id
          ).once

          expect(Gitlab::ProjectStatsRefreshConflictsLogger).to receive(:warn_artifact_deletion_during_stats_refresh).with(
            method: 'Ci::JobArtifacts::DestroyBatchService#execute',
            project_id: artifact_under_refresh_2.project.id
          ).once

          expect { subject }.to change { Ci::JobArtifact.count }.by(-4)
        end

        it_behaves_like 'avoiding N+1 queries'
      end

      context 'and skip_projects_on_refresh is set to true' do
        let(:skip_projects_on_refresh) { true }

        it 'logs the projects undergoing refresh and excludes the artifacts from deletion', :aggregate_failures do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger).to receive(:warn_skipped_artifact_deletion_during_stats_refresh).with(
            method: 'Ci::JobArtifacts::DestroyBatchService#execute',
            project_ids: match_array([artifact_under_refresh_1.project.id, artifact_under_refresh_2.project.id])
          )

          expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
          expect(Ci::JobArtifact.where(id: artifact_under_refresh_1.id)).to exist
          expect(Ci::JobArtifact.where(id: artifact_under_refresh_2.id)).to exist
          expect(Ci::JobArtifact.where(id: artifact_under_refresh_3.id)).to exist
        end

        it_behaves_like 'avoiding N+1 queries'
      end
    end

    context 'when an artifact belongs to an orphaned project' do
      let(:artifacts) { Ci::JobArtifact.where(id: [orphaned_artifact.id]) }
      let!(:orphaned_artifact) do
        create(:ci_job_artifact, :zip)
      end

      before do
        orphaned_artifact.update!(project_id: 0)
      end

      it 'deletes the artifact' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      end

      context 'when skip_projects_on_refresh is set to true' do
        let(:skip_projects_on_refresh) { true }

        it 'deletes the artifact' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
        end
      end
    end

    context 'when artifact belongs to a project not undergoing refresh' do
      context 'and skip_projects_on_refresh is set to false (default)' do
        it 'does not log any warnings', :aggregate_failures do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger).not_to receive(:warn_artifact_deletion_during_stats_refresh)

          expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
        end
      end

      context 'and skip_projects_on_refresh is set to true' do
        let(:skip_projects_on_refresh) { true }

        it 'does not log any warnings', :aggregate_failures do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger).not_to receive(:warn_skipped_artifact_deletion_during_stats_refresh)

          expect { subject }.to change { Ci::JobArtifact.count }.by(-2)
        end
      end
    end

    context 'ProjectStatistics', :sidekiq_inline do
      let_it_be(:project_1) { create(:project) }
      let_it_be(:project_2) { create(:project) }

      let(:artifact_with_file) { create(:ci_job_artifact, :zip, project: project_1) }
      let(:artifact_with_file_2) { create(:ci_job_artifact, :zip, project: project_1) }
      let(:artifact_without_file) { create(:ci_job_artifact, project: project_2) }
      let!(:artifacts) { Ci::JobArtifact.where(id: [artifact_with_file.id, artifact_without_file.id, artifact_with_file_2.id]) }

      it 'updates project statistics by the relevant amount' do
        expected_amount = -(artifact_with_file.size + artifact_with_file_2.size)

        expect { execute }
          .to change { project_1.statistics.reload.build_artifacts_size }.by(expected_amount)
          .and change { project_2.statistics.reload.build_artifacts_size }.by(0)
      end

      it 'increments project statistics with artifact size as amount and job artifact id as ref' do
        project_1_increments = [
          have_attributes(amount: -artifact_with_file.size, ref: artifact_with_file.id),
          have_attributes(amount: -artifact_with_file_2.file.size, ref: artifact_with_file_2.id)
        ]
        project_2_increments = [have_attributes(amount: 0, ref: artifact_without_file.id)]

        expect(ProjectStatistics).to receive(:bulk_increment_statistic).with(project_1, :build_artifacts_size, match_array(project_1_increments))
        expect(ProjectStatistics).to receive(:bulk_increment_statistic).with(project_2, :build_artifacts_size, match_array(project_2_increments))

        execute
      end

      context 'with update_stats: false' do
        subject(:execute) { service.execute(update_stats: false) }

        it 'does not update project statistics' do
          expect { execute }.not_to change { [project_1.statistics.reload.build_artifacts_size, project_2.statistics.reload.build_artifacts_size] }
        end

        it 'returns statistic updates per project' do
          project_1_updates = [
            have_attributes(amount: -artifact_with_file.size, ref: artifact_with_file.id),
            have_attributes(amount: -artifact_with_file_2.file.size, ref: artifact_with_file_2.id)
          ]
          project_2_updates = [have_attributes(amount: 0, ref: artifact_without_file.id)]

          expected_updates = {
            statistics_updates: {
              project_1 => match_array(project_1_updates),
              project_2 => project_2_updates
            }
          }

          expect(execute).to match(a_hash_including(expected_updates))
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
        is_expected.to eq(destroyed_artifacts_count: 0, destroyed_ids: [], statistics_updates: {}, status: :success)
      end
    end
  end
end
