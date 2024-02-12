# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportUpload, type: :model do
  subject { described_class.new(relation_export: project_relation_export) }

  let_it_be(:project_relation_export) { create(:project_relation_export) }

  describe 'associations' do
    it { is_expected.to belong_to(:relation_export) }
  end

  describe '.for_project_export_jobs' do
    let_it_be(:project_export_job_1) { create(:project_export_job) }
    let_it_be(:project_export_job_2) { create(:project_export_job) }

    let_it_be(:relation_export_1) { create(:project_relation_export, project_export_job: project_export_job_1) }
    let_it_be(:relation_export_2) { create(:project_relation_export, project_export_job: project_export_job_2) }
    let_it_be(:relation_export_3) do
      create(:project_relation_export, project_export_job: project_export_job_1, relation: 'milestones')
    end

    let_it_be(:relation_export_upload_1) { create(:relation_export_upload, relation_export: relation_export_1) }
    let_it_be(:relation_export_upload_2) { create(:relation_export_upload, relation_export: relation_export_2) }
    let_it_be(:relation_export_upload_3) { create(:relation_export_upload, relation_export: relation_export_1) }

    it 'returns RelationExportUploads for a single ProjectExportUpload id' do
      project_export_job_id = project_export_job_1.id

      expect(described_class.for_project_export_jobs(project_export_job_id))
        .to contain_exactly(relation_export_upload_1, relation_export_upload_3)
    end

    it 'returns RelationExportUploads for multiple ProjectExportUpload ids' do
      project_export_job_ids = [project_export_job_1, project_export_job_2].map(&:id)

      expect(described_class.for_project_export_jobs(project_export_job_ids))
        .to contain_exactly(relation_export_upload_1, relation_export_upload_2, relation_export_upload_3)
    end
  end

  it 'stores export file' do
    stub_uploads_object_storage(ImportExportUploader, enabled: false)

    filename = 'labels.tar.gz'
    subject.export_file = fixture_file_upload("spec/fixtures/gitlab/import_export/#{filename}")

    subject.save!

    url = "/uploads/-/system/projects/import_export/relation_export_upload/export_file/#{subject.id}/#{filename}"
    expect(subject.export_file.url).to eq(url)
  end
end
