# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PruneStaleProjectExportJobs, feature_category: :importers do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_export_jobs) { table(:project_export_jobs) }
  let(:project_relation_exports) { table(:project_relation_exports) }
  let(:uploads) { table(:project_relation_export_uploads) }

  subject(:perform_migration) do
    described_class.new(
      start_id: 1,
      end_id: 300,
      batch_table: :project_export_jobs,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'removes export jobs and associated relations older than 7 days' do
    namespaces.create!(id: 1000, name: "Sally", path: 'sally')
    projects.create!(id: 1, namespace_id: 1000, project_namespace_id: 1000)

    project = Project.find 1

    project_export_jobs.create!(id: 10, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 37.months.ago)
    project_export_jobs.create!(id: 20, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 12.months.ago)
    project_export_jobs.create!(id: 30, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 8.days.ago)
    project_export_jobs.create!(id: 40, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 1.day.ago)
    project_export_jobs.create!(id: 50, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 2.days.ago)
    project_export_jobs.create!(id: 60, project_id: project.id, jid: SecureRandom.hex(10), updated_at: 6.days.ago)

    project_relation_exports.create!(id: 100, project_export_job_id: 10, relation: 'Project')
    project_relation_exports.create!(id: 200, project_export_job_id: 20, relation: 'Project')
    project_relation_exports.create!(id: 300, project_export_job_id: 30, relation: 'Project')
    project_relation_exports.create!(id: 400, project_export_job_id: 40, relation: 'Project')
    project_relation_exports.create!(id: 500, project_export_job_id: 50, relation: 'Project')
    project_relation_exports.create!(id: 600, project_export_job_id: 60, relation: 'Project')

    uploads.create!(project_relation_export_id: 100, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")
    uploads.create!(project_relation_export_id: 200, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")
    uploads.create!(project_relation_export_id: 300, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")
    uploads.create!(project_relation_export_id: 400, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")
    uploads.create!(project_relation_export_id: 500, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")
    uploads.create!(project_relation_export_id: 600, export_file: "#{SecureRandom.alphanumeric(5)}_export.tar.gz")

    expect(project_export_jobs.all.size).to eq(6)
    expect(project_relation_exports.all.size).to eq(6)
    expect(uploads.all.size).to eq(6)

    expect { perform_migration }
      .to change { project_export_jobs.count }.by(-3)
      .and change { project_relation_exports.count }.by(-3)
      .and change { uploads.count }.by(-3)

    expect(project_export_jobs.all.size).to eq(3)
    expect(project_relation_exports.all.size).to eq(3)
    expect(uploads.all.size).to eq(3)
  end
end
