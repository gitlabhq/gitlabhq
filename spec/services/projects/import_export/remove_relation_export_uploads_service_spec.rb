# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RemoveRelationExportUploadsService, feature_category: :importers do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:export_job) { create(:project_export_job, project: project) }
    let_it_be(:relation_export) { create(:project_relation_export, project_export_job: export_job) }
    let_it_be(:relation_export_upload) { create(:relation_export_upload, relation_export: relation_export) }

    subject(:service) { described_class.new(project) }

    it 'enqueues RemoveRelationExportUploadWorker for each upload' do
      relation_export_upload.update!(
        export_file: fixture_file_upload('spec/fixtures/gitlab/import_export/labels.tar.gz')
      )

      expect(Projects::ImportExport::RemoveRelationExportUploadWorker)
        .to receive(:perform_async).with(relation_export_upload.uploads.first.id)

      service.execute
    end

    it 'returns a success response' do
      expect(service.execute).to be_success
    end

    context 'when there are no relation export uploads' do
      it 'does not enqueue RemoveRelationExportUploadWorker' do
        relation_export_upload.destroy!
        project.reload

        expect(Projects::ImportExport::RemoveRelationExportUploadWorker)
          .not_to receive(:perform_async)

        service.execute
      end
    end
  end
end
