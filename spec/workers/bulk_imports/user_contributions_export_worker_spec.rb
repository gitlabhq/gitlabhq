# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UserContributionsExportWorker, :freeze_time, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:job_args) { [project.id, project.class.name, user.id] }
  let(:current_time) { Time.current }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      before do
        allow(described_class).to receive(:perform_in).twice
      end

      shared_examples 'user contributions are still being cached during export' do
        it 'does not begin exporting user contributions' do
          perform_multiple(job_args)

          user_contributions_export = project.bulk_import_exports.find_by(relation: 'user_contributions')
          expect(user_contributions_export).to be_nil
        end

        it 're-enqueues itself' do
          expect(described_class).to receive(:perform_in).with(20.seconds, *job_args, current_time).twice

          perform_multiple(job_args)
        end
      end

      shared_examples 'user contributions are incomplete due to export failure' do
        it 'does not begin exporting user contributions' do
          perform_multiple(job_args)

          user_contributions_export = project.bulk_import_exports.find_by(relation: 'user_contributions')
          expect(user_contributions_export).to be_nil
        end

        it 'does not re-enqueue itself' do
          expect(described_class).not_to receive(:perform_in)

          perform_multiple(job_args)
        end

        it 'logs an error' do
          logger = Gitlab::Export::Logger.build
          allow(Gitlab::Export::Logger).to receive(:build).and_return(logger)

          expect(logger).to receive(:error).with(
            hash_including(
              importer: 'gitlab_migration',
              project_id: project.id,
              project_name: project.name,
              project_path: project.full_path
            )
          ).twice

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

      context 'when all exports have finished or failed' do
        let!(:issues_export) { create(:bulk_import_export, :finished, project: project, relation: 'issues') }
        let!(:merge_requests_export) do
          create(:bulk_import_export, :failed, project: project, relation: 'merge_requests')
        end

        it_behaves_like 'user contributions export is started'
      end

      context 'when an export relating to users is still incomplete' do
        let!(:issues_export) { create(:bulk_import_export, :finished, project: project, relation: 'issues') }
        let!(:merge_requests_export) do
          create(:bulk_import_export, :started, project: project, relation: 'merge_requests')
        end

        it_behaves_like 'user contributions are still being cached during export'
      end

      context 'when an export not relating to users is still incomplete' do
        let!(:labels_export) { create(:bulk_import_export, :started, project: project, relation: 'labels') }

        it_behaves_like 'user contributions export is started'
      end

      context 'when some exports relating to users and some not relating to users are still incomplete' do
        let!(:issues_export) { create(:bulk_import_export, :started, project: project, relation: 'issues') }
        let!(:labels_export) { create(:bulk_import_export, :started, project: project, relation: 'labels') }

        it_behaves_like 'user contributions are still being cached during export'
      end

      context 'when no exports have been created yet' do
        it_behaves_like 'user contributions are still being cached during export'

        context 'and no exports have been created for more than 6 hours' do
          let(:job_args) { [project.id, project.class.name, user.id, current_time - 7.hours] }

          it_behaves_like 'user contributions are incomplete due to export failure'
        end
      end
    end
  end
end
