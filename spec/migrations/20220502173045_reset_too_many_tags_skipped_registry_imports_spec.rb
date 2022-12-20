# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResetTooManyTagsSkippedRegistryImports, :aggregate_failures, feature_category: :container_registry do
  let(:migration) { described_class::MIGRATION }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:container_repositories) { table(:container_repositories) }

  let!(:namespace) { namespaces.create!(id: 1, name: 'namespace', path: 'namespace') }
  let!(:project) { projects.create!(id: 1, name: 'project', path: 'project', project_namespace_id: 1, namespace_id: 1) }

  let!(:container_repository1) do
    container_repositories.create!(
      name: 'container_repository1',
      project_id: 1,
      migration_state: 'import_skipped',
      migration_skipped_reason: 2
    )
  end

  let!(:container_repository2) do
    container_repositories.create!(
      name: 'container_repository2',
      project_id: 1,
      migration_state: 'import_skipped',
      migration_skipped_reason: 2
    )
  end

  let!(:container_repository3) do
    container_repositories.create!(
      name: 'container_repository3',
      project_id: 1,
      migration_state: 'import_skipped',
      migration_skipped_reason: 2
    )
  end

  # this should not qualify for the migration
  let!(:container_repository4) do
    container_repositories.create!(
      name: 'container_repository4',
      project_id: 1,
      migration_state: 'default'
    )
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'schedules jobs to reset skipped registry imports' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(migration).to be_scheduled_delayed_migration(
          2.minutes, container_repository1.id, container_repository2.id)
        expect(migration).to be_scheduled_delayed_migration(
          4.minutes, container_repository3.id, container_repository3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
