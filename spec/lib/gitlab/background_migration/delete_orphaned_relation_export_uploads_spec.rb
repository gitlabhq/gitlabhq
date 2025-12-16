# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedRelationExportUploads, feature_category: :importers do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:project_export_jobs) { table(:project_export_jobs) }
  let(:project_relation_exports) { table(:project_relation_exports) }
  let(:project_relation_export_uploads) { table(:project_relation_export_uploads) }
  let(:uploads) { table(:uploads) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:user) do
    users.create!(
      email: 'test@example.com',
      username: 'test',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:export_job) do
    project_export_jobs.create!(
      project_id: project.id,
      jid: 'test_jid',
      status: 0,
      user_id: user.id
    )
  end

  let!(:relation_export) do
    project_relation_exports.create!(
      project_id: project.id,
      project_export_job_id: export_job.id,
      relation: 'test_relation',
      status: 0
    )
  end

  let!(:valid_relation_export_upload) do
    project_relation_export_uploads.create!(
      project_relation_export_id: relation_export.id,
      project_id: project.id,
      export_file: 'valid/export.tar.gz'
    )
  end

  let!(:valid_upload) do
    uploads.create!(
      model_type: 'Projects::ImportExport::RelationExportUpload',
      model_id: valid_relation_export_upload.id,
      uploader: 'ImportExportUploader',
      path: 'valid/path/file.tar.gz',
      size: 1024,
      store: 1
    )
  end

  let!(:orphaned_upload_1) do
    uploads.create!(
      model_type: 'Projects::ImportExport::RelationExportUpload',
      model_id: non_existing_record_id,
      uploader: 'ImportExportUploader',
      path: 'orphaned/path/file1.tar.gz',
      size: 2048,
      store: 1,
      project_id: project.id
    )
  end

  let!(:orphaned_upload_2) do
    uploads.create!(
      model_type: 'Projects::ImportExport::RelationExportUpload',
      model_id: non_existing_record_id - 1,
      uploader: 'ImportExportUploader',
      path: 'orphaned/path/file2.tar.gz',
      size: 3072,
      store: 2,
      project_id: project.id
    )
  end

  let!(:other_model_upload) do
    uploads.create!(
      model_type: 'Project',
      model_id: project.id,
      uploader: 'FileUploader',
      path: 'other/path/file.jpg',
      size: 512,
      store: 1
    )
  end

  let(:starting_id) { uploads.minimum(:id) }
  let(:end_id) { uploads.maximum(:id) }

  let(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :uploads,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'deletes orphaned RelationExportUpload uploads but keeps valid ones' do
      expect(uploads.count).to eq(4)

      migration.perform

      expect(uploads.count).to eq(2)
      expect(uploads.find_by(id: valid_upload.id)).to be_present
      expect(uploads.find_by(id: other_model_upload.id)).to be_present
      expect(uploads.find_by(id: orphaned_upload_1.id)).to be_nil
      expect(uploads.find_by(id: orphaned_upload_2.id)).to be_nil
    end

    context 'when there are no orphaned uploads' do
      before do
        uploads.where(id: [orphaned_upload_1.id, orphaned_upload_2.id]).delete_all
      end

      it 'does not delete anything' do
        expect(uploads.count).to eq(2)

        migration.perform

        expect(uploads.count).to eq(2)
      end
    end
  end
end
