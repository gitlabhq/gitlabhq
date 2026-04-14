# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UserContributionsExportWorker, :freeze_time, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:offline_export) { create(:offline_export, :with_configuration, user: user) }

  let(:job_args) { [project.id, project.class.name, user.id, offline_export.id] }
  let(:current_time) { Time.current }
  let(:logger) { Gitlab::Export::Logger.build }
  let_it_be(:stale_export_timeout) { 7.hours.ago }

  before do
    allow(Gitlab::Export::Logger).to receive(:build).and_return(logger)
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      before do
        allow(described_class).to receive(:perform_in).twice
        stub_offline_import_object_storage(offline_export.configuration)
      end

      shared_examples 'user contributions are still being cached during export' do
        it 'does not start exporting user contributions' do
          perform_multiple(job_args)

          user_contributions_export = project.bulk_import_exports.find_by(
            offline_export: offline_export, relation: 'user_contributions'
          )

          expect(user_contributions_export).to be_pending
        end

        it 're-enqueues itself' do
          expect(described_class).to receive(:perform_in).with(
            20.seconds, project.id, project.class.name, user.id, offline_export.id, enqueued_at: current_time
          ).twice

          perform_multiple(job_args)
        end
      end

      shared_examples 'user contributions are incomplete due to export failure' do
        it 'fails the user contributions relation export', :aggregate_failures do
          perform_multiple(job_args)

          user_contributions_export = project.bulk_import_exports.find_by(
            offline_export: offline_export, relation: 'user_contributions'
          )

          expect(user_contributions_export).to be_failed
          expect(offline_export.reload.has_failures?).to be(true)
        end

        it 'does not re-enqueue itself' do
          expect(described_class).not_to receive(:perform_in)

          perform_multiple(job_args)
        end

        it 'logs an error' do
          expect(logger).to receive(:error).with(
            hash_including(
              importer: 'gitlab_migration',
              offline_export_id: offline_export.id,
              project_id: project.id,
              project_name: project.name,
              project_path: project.full_path
            )
          )

          perform_multiple(job_args)
        end
      end

      shared_examples 'user contributions export is started' do
        it 'begins exporting user contributions' do
          perform_multiple(job_args)

          user_contributions_export = project.bulk_import_exports.find_by(relation: 'user_contributions')
          expect(user_contributions_export).to be_present
        end

        it 'does not re-enqueue itself' do
          expect(described_class).not_to receive(:perform_in)

          perform_multiple(job_args)
        end
      end

      shared_examples 'user contributions have already completed', :aggregate_failures do
        it 'does not re-enqueue or export again' do
          export_service_double = instance_double(BulkImports::UserContributionsExportService)

          expect(described_class).not_to receive(:perform_in)
          expect(export_service_double).not_to receive(:execute)

          perform_multiple(job_args)
        end
      end

      context 'when all exports have finished or failed' do
        let!(:issues_export) do
          create(:bulk_import_export, :finished, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:merge_requests_export) do
          create(:bulk_import_export, :failed, :offline, project: project, relation: 'merge_requests',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions export is started'
      end

      context 'when an export relating to users is still in started state' do
        let!(:issues_export) do
          create(:bulk_import_export, :finished, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:merge_requests_export) do
          create(:bulk_import_export, :started, :offline, project: project, relation: 'merge_requests',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions are still being cached during export'

        context 'if the export is stuck in started state' do
          before do
            merge_requests_export.update!(updated_at: stale_export_timeout)
          end

          it_behaves_like 'user contributions export is started'
        end
      end

      context 'when an export relating to users is still in pending state' do
        let!(:issues_export) do
          create(:bulk_import_export, :finished, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:merge_requests_export) do
          create(:bulk_import_export, :pending, :offline, project: project, relation: 'merge_requests',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions are still being cached during export'

        context 'if the export is stuck in pending state' do
          before do
            merge_requests_export.update!(updated_at: stale_export_timeout)
          end

          it_behaves_like 'user contributions export is started'
        end
      end

      context 'when an export not relating to users is still incomplete' do
        let!(:labels_export) do
          create(:bulk_import_export, :started, :offline, project: project, relation: 'labels',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions export is started'
      end

      context 'when both user-related and non-user-related exports exist with different statuses' do
        let!(:issues_export) do
          create(:bulk_import_export, :started, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:labels_export) do
          create(:bulk_import_export, :started, :offline, project: project, relation: 'labels',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions are still being cached during export'

        context 'when user-related exports are stale (older than timeout limit)' do
          before do
            issues_export.update!(updated_at: stale_export_timeout)
          end

          it_behaves_like 'user contributions export is started'
        end

        context 'when user-related exports are still active (not stale)' do
          before do
            # Make non-user exports stale, but this shouldn't affect the decision
            labels_export.update!(updated_at: stale_export_timeout)
          end

          # Even though non-user-related exports are stale, the worker should still cache contributions
          # because user-related exports are still active
          it_behaves_like 'user contributions are still being cached during export'
        end
      end

      context 'when no exports have been created yet' do
        it_behaves_like 'user contributions are still being cached during export'

        context 'and no exports have been created for more than 6 hours' do
          let(:job_args) do
            [project.id, project.class.name, user.id, offline_export.id, { 'enqueued_at' => current_time - 7.hours }]
          end

          it_behaves_like 'user contributions are incomplete due to export failure'
        end
      end

      context 'when user contributions have already finished' do
        let!(:user_contributions_export) do
          create(:bulk_import_export, :finished, project: project, relation: 'user_contributions',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions have already completed'
      end

      context 'when user contributions have already failed' do
        let!(:user_contributions_export) do
          create(:bulk_import_export, :failed, project: project, relation: 'user_contributions',
            offline_export: offline_export)
        end

        it_behaves_like 'user contributions have already completed'
      end

      context 'when direct transfer exports exist but no offline exports' do
        let!(:direct_transfer_issues_export) do
          create(:bulk_import_export, :started, project: project, relation: 'issues')
        end

        it_behaves_like 'user contributions are still being cached during export'

        context 'and no offline exports have been created for more than 6 hours' do
          let(:job_args) do
            [project.id, project.class.name, user.id, offline_export.id, { 'enqueued_at' => current_time - 7.hours }]
          end

          it_behaves_like 'user contributions are incomplete due to export failure'
        end
      end

      context 'when direct transfer exports are in progress but offline exports are complete' do
        let!(:offline_issues_export) do
          create(:bulk_import_export, :finished, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:direct_transfer_issues_export) do
          create(:bulk_import_export, :started, project: project, relation: 'issues')
        end

        let!(:direct_transfer_merge_requests_export) do
          create(:bulk_import_export, :pending, project: project, relation: 'merge_requests')
        end

        it_behaves_like 'user contributions export is started'
      end

      context 'when offline exports are in progress but direct transfer exports are complete' do
        let!(:offline_issues_export) do
          create(:bulk_import_export, :started, :offline, project: project, relation: 'issues',
            offline_export: offline_export)
        end

        let!(:direct_transfer_issues_export) do
          create(:bulk_import_export, :finished, project: project, relation: 'issues')
        end

        let!(:direct_transfer_merge_requests_export) do
          create(:bulk_import_export, :finished, project: project, relation: 'merge_requests')
        end

        it_behaves_like 'user contributions are still being cached during export'
      end
    end
  end

  describe '.sidekiq_retries_exhausted', :aggregate_failures do
    it 'fails the user contributions export and logs and tracks the exception' do
      exception = StandardError.new('*' * 300)

      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(
          exception,
          portable_id: project.id,
          portable_type: project.class.name,
          offline_export_id: offline_export.id
        )

      expect(logger).to receive(:error).with(
        hash_including(
          importer: 'gitlab_migration',
          offline_export_id: offline_export.id,
          project_id: project.id,
          project_name: project.name,
          project_path: project.full_path
        )
      )

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => job_args }, exception)

      user_contributions_export = project.bulk_import_exports.find_by(
        offline_export: offline_export, relation: 'user_contributions'
      )

      expect(user_contributions_export).to be_failed
      expect(user_contributions_export.error.size).to eq(255)
    end
  end
end
