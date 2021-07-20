# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedDeployments, :migration, schema: 20210617161348 do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:environment) { table(:environments).create!(name: 'production', slug: 'production', project_id: project.id) }
  let(:background_migration_jobs) { table(:background_migration_jobs) }

  before do
    create_deployment!(environment.id, project.id)
    create_deployment!(non_existing_record_id, project.id)
  end

  it 'deletes only orphaned deployments' do
    expect(valid_deployments.pluck(:id)).not_to be_empty
    expect(orphaned_deployments.pluck(:id)).not_to be_empty

    subject.perform(table(:deployments).minimum(:id), table(:deployments).maximum(:id))

    expect(valid_deployments.pluck(:id)).not_to be_empty
    expect(orphaned_deployments.pluck(:id)).to be_empty
  end

  it 'marks jobs as done' do
    first_job = background_migration_jobs.create!(
      class_name: 'DeleteOrphanedDeployments',
      arguments: [table(:deployments).minimum(:id), table(:deployments).minimum(:id)]
    )

    second_job = background_migration_jobs.create!(
      class_name: 'DeleteOrphanedDeployments',
      arguments: [table(:deployments).maximum(:id), table(:deployments).maximum(:id)]
    )

    subject.perform(table(:deployments).minimum(:id), table(:deployments).minimum(:id))

    expect(first_job.reload.status).to eq(Gitlab::Database::BackgroundMigrationJob.statuses[:succeeded])
    expect(second_job.reload.status).to eq(Gitlab::Database::BackgroundMigrationJob.statuses[:pending])
  end

  private

  def valid_deployments
    table(:deployments).where('EXISTS (SELECT 1 FROM environments WHERE deployments.environment_id = environments.id)')
  end

  def orphaned_deployments
    table(:deployments).where('NOT EXISTS (SELECT 1 FROM environments WHERE deployments.environment_id = environments.id)')
  end

  def create_deployment!(environment_id, project_id)
    table(:deployments).create!(
      environment_id: environment_id,
      project_id: project_id,
      ref: 'master',
      tag: false,
      sha: 'x',
      status: 1,
      iid: table(:deployments).count + 1)
  end
end
