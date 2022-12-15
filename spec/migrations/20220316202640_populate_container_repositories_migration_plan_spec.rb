# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateContainerRepositoriesMigrationPlan, :aggregate_failures, feature_category: :container_registry do
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:container_repositories) { table(:container_repositories) }

  let!(:namespace) { namespaces.create!(id: 1, name: 'namespace', path: 'namespace') }
  let!(:project) { projects.create!(id: 1, name: 'project', path: 'project', namespace_id: 1) }
  let!(:container_repository1) { container_repositories.create!(name: 'container_repository1', project_id: 1) }
  let!(:container_repository2) { container_repositories.create!(name: 'container_repository2', project_id: 1) }
  let!(:container_repository3) { container_repositories.create!(name: 'container_repository3', project_id: 1) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'schedules jobs for container_repositories to populate migration_state' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          2.minutes, container_repository1.id, container_repository2.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          4.minutes, container_repository3.id, container_repository3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
