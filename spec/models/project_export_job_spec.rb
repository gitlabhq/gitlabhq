# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportJob, feature_category: :importers, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:relation_exports) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:jid) }
    it { is_expected.to validate_presence_of(:status) }
  end

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
      expect { described_class.prune_expired_jobs }.to change { described_class.count }.by(-3)

      expect(described_class.find_by(id: old_job_1.id)).to be_nil
      expect(described_class.find_by(id: old_job_2.id)).to be_nil
      expect(described_class.find_by(id: old_job_3.id)).to be_nil

      expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_1.id)).to be_nil
      expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_2.id)).to be_nil
      expect(Projects::ImportExport::RelationExport.find_by(id: old_relation_export_3.id)).to be_nil

      expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_1.id)).to be_nil
      expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_2.id)).to be_nil
      expect(Projects::ImportExport::RelationExportUpload.find_by(id: old_upload_3.id)).to be_nil
    end

    it 'does not delete associated records for jobs younger than 7 days' do
      described_class.prune_expired_jobs

      expect(fresh_job_1.reload).to be_present
      expect(fresh_job_2.reload).to be_present
      expect(fresh_job_3.reload).to be_present
      expect(fresh_relation_export_1.reload).to be_present
      expect(fresh_upload_1.reload).to be_present
    end
  end
end
