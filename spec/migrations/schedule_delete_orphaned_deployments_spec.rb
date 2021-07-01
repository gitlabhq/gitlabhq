# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ScheduleDeleteOrphanedDeployments, :sidekiq, schema: 20210617161348 do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let!(:environment) { table(:environments).create!(name: 'production', slug: 'production', project_id: project.id) }
  let(:background_migration_jobs) { table(:background_migration_jobs) }

  before do
    create_deployment!(environment.id, project.id)
    create_deployment!(environment.id, project.id)
    create_deployment!(environment.id, project.id)
    create_deployment!(non_existing_record_id, project.id)
    create_deployment!(non_existing_record_id, project.id)
    create_deployment!(non_existing_record_id, project.id)
    create_deployment!(non_existing_record_id, project.id)

    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'schedules DeleteOrphanedDeployments background jobs' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(7)
        table(:deployments).find_each do |deployment|
          expect(described_class::MIGRATION).to be_scheduled_migration(deployment.id, deployment.id)
        end
      end
    end
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
