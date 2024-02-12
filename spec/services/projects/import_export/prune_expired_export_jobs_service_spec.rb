# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::PruneExpiredExportJobsService, feature_category: :importers do
  describe '#execute' do
    context 'when pruning expired jobs' do
      let_it_be(:old_job_1) { create(:project_export_job, updated_at: 37.months.ago) }
      let_it_be(:old_job_2) { create(:project_export_job, updated_at: 12.months.ago) }
      let_it_be(:old_job_3) { create(:project_export_job, updated_at: 8.days.ago) }
      let_it_be(:fresh_job_1) { create(:project_export_job, updated_at: 1.day.ago) }
      let_it_be(:fresh_job_2) { create(:project_export_job, updated_at: 2.days.ago) }
      let_it_be(:fresh_job_3) { create(:project_export_job, updated_at: 6.days.ago) }

      let_it_be(:old_relation_export_1) { create(:project_relation_export, project_export_job_id: old_job_1.id) }
      let_it_be(:old_relation_export_2) { create(:project_relation_export, project_export_job_id: old_job_2.id) }
      let_it_be(:old_relation_export_3) { create(:project_relation_export, project_export_job_id: old_job_3.id) }
      let_it_be(:fresh_relation_export_1) { create(:project_relation_export, project_export_job_id: fresh_job_1.id) }

      let_it_be(:old_upload_1) { create(:relation_export_upload, project_relation_export_id: old_relation_export_1.id) }
      let_it_be(:old_upload_2) { create(:relation_export_upload, project_relation_export_id: old_relation_export_2.id) }
      let_it_be(:old_upload_3) { create(:relation_export_upload, project_relation_export_id: old_relation_export_3.id) }
      let_it_be(:fresh_upload_1) do
        create(
          :relation_export_upload,
          project_relation_export_id: fresh_relation_export_1.id
        )
      end

      it 'prunes jobs and associations older than 7 days' do
        old_uploads = Upload.for_model_type_and_id(
          Projects::ImportExport::RelationExportUpload,
          [old_upload_1, old_upload_2, old_upload_3].map(&:id)
        )
        old_upload_file_paths = Uploads::Local.new.keys(old_uploads)

        expect(DeleteStoredFilesWorker).to receive(:perform_async).with(Uploads::Local, old_upload_file_paths)

        expect { described_class.execute }.to change { ProjectExportJob.count }.by(-3)

        expect(ProjectExportJob.find_by(id: old_job_1.id)).to be_nil
        expect(ProjectExportJob.find_by(id: old_job_2.id)).to be_nil
        expect(ProjectExportJob.find_by(id: old_job_3.id)).to be_nil

        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_1.id)).to be_nil
        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_2.id)).to be_nil
        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_3.id)).to be_nil

        expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_1.id)).to be_nil
        expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_2.id)).to be_nil
        expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_3.id)).to be_nil

        expect(old_uploads.reload).to be_empty
      end

      it 'does not delete associated records for jobs younger than 7 days' do
        described_class.execute

        expect(fresh_job_1.reload).to be_present
        expect(fresh_job_2.reload).to be_present
        expect(fresh_job_3.reload).to be_present
        expect(fresh_relation_export_1.reload).to be_present
        expect(fresh_upload_1.reload).to be_present
        expect(
          Upload.for_model_type_and_id(Projects::ImportExport::RelationExportUpload, fresh_upload_1.id)
        ).to be_present
      end
    end
  end
end
