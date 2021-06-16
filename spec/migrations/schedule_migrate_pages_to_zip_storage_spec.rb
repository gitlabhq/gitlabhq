# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleMigratePagesToZipStorage, :sidekiq_might_not_need_inline, schema: 20201231133921 do
  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:metadata_table) { table(:project_pages_metadata) }
  let(:deployments_table) { table(:pages_deployments) }

  let(:namespace) { namespaces_table.create!(path: "group", name: "group") }

  def create_project_metadata(path, deployed, with_deployment)
    project = projects_table.create!(path: path, namespace_id: namespace.id)

    deployment_id = nil

    if with_deployment
      deployment_id = deployments_table.create!(project_id: project.id, file_store: 1, file: '1', file_count: 1, file_sha256: '123', size: 1).id
    end

    metadata_table.create!(project_id: project.id, deployed: deployed, pages_deployment_id: deployment_id)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        create_project_metadata("not-deployed-project", false, false)

        first_id = create_project_metadata("project1", true, false).id
        last_id = create_project_metadata("project2", true, false).id

        create_project_metadata("project-with-deployment", true, true)

        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(5.minutes, first_id, last_id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end
end
