# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::PruneExpiredExportJobsService, feature_category: :importers do
  describe '#execute', :freeze_time do
    let_it_be(:project) { create(:project) }

    let!(:old_job_1) { create(:project_export_job, updated_at: 37.months.ago, project: project) }
    let!(:old_job_2) { create(:project_export_job, updated_at: 12.months.ago, project: project) }
    let!(:old_job_3) { create(:project_export_job, updated_at: 8.days.ago, project: project) }
    let!(:fresh_job_1) { create(:project_export_job, updated_at: 1.day.ago, project: project) }
    let!(:fresh_job_2) { create(:project_export_job, updated_at: 2.days.ago, project: project) }
    let!(:fresh_job_3) { create(:project_export_job, updated_at: 6.days.ago, project: project) }

    it 'prunes ProjectExportJob records and associations older than 7 days' do
      expect { described_class.execute }.to change { ProjectExportJob.count }.by(-3)

      expect(ProjectExportJob.find_by(id: old_job_1.id)).to be_nil
      expect(ProjectExportJob.find_by(id: old_job_2.id)).to be_nil
      expect(ProjectExportJob.find_by(id: old_job_3.id)).to be_nil

      expect(fresh_job_1.reload).to be_present
      expect(fresh_job_2.reload).to be_present
      expect(fresh_job_3.reload).to be_present
    end

    it 'prunes ProjectExportJob records in batches' do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      allow(described_class).to receive(:delete_uploads_for_expired_jobs).and_return(nil)
      expect(ProjectExportJob).to receive(:prunable).and_call_original.exactly(3).times

      described_class.execute
    end

    context 'with associated RelationExport records' do
      let!(:old_relation_export_1) { create(:project_relation_export, project_export_job_id: old_job_1.id) }
      let!(:old_relation_export_2) { create(:project_relation_export, project_export_job_id: old_job_2.id) }
      let!(:old_relation_export_3) { create(:project_relation_export, project_export_job_id: old_job_3.id) }
      let!(:fresh_relation_export_1) { create(:project_relation_export, project_export_job_id: fresh_job_1.id) }

      it 'prunes expired RelationExport records' do
        expect { described_class.execute }.to change { Projects::ImportExport::RelationExport.count }.by(-3)

        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_1.id)).to be_nil
        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_2.id)).to be_nil
        expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_3.id)).to be_nil

        expect(fresh_relation_export_1.reload).to be_present
      end

      context 'and RelationExportUploads' do
        let!(:old_upload_1) { create(:relation_export_upload, project_relation_export_id: old_relation_export_1.id) }
        let!(:old_upload_2) { create(:relation_export_upload, project_relation_export_id: old_relation_export_2.id) }
        let!(:old_upload_3) { create(:relation_export_upload, project_relation_export_id: old_relation_export_3.id) }
        let!(:fresh_upload_1) do
          create(
            :relation_export_upload,
            project_relation_export_id: fresh_relation_export_1.id
          )
        end

        let(:old_uploads) do
          Upload.for_model_type_and_id(
            Projects::ImportExport::RelationExportUpload,
            [old_upload_1, old_upload_2, old_upload_3].map(&:id)
          )
        end

        it 'prunes expired RelationExportUpload records' do
          expect { described_class.execute }.to change { Projects::ImportExport::RelationExportUpload.count }.by(-3)

          expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_1.id)).to be_nil
          expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_2.id)).to be_nil
          expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_3.id)).to be_nil
        end

        it 'deletes associated Upload records' do
          described_class.execute

          expect(old_uploads).to be_empty

          expect(fresh_upload_1.reload).to be_present
          expect(
            Upload.for_model_type_and_id(Projects::ImportExport::RelationExportUpload, fresh_upload_1.id)
          ).to be_present
        end

        it 'deletes stored upload files' do
          old_upload_file_paths = Uploads::Local.new.keys(old_uploads)

          expect(DeleteStoredFilesWorker).to receive(:perform_async).with(Uploads::Local, old_upload_file_paths)

          described_class.execute
        end

        it 'deletes expired uploads in batches' do
          stub_const("#{described_class.name}::BATCH_SIZE", 2)

          expect(Upload).to receive(:finalize_fast_destroy).and_call_original.twice

          described_class.execute
        end
      end
    end
  end
end
