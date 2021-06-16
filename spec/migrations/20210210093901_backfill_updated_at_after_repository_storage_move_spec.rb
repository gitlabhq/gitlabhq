# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_updated_at_after_repository_storage_move')

RSpec.describe BackfillUpdatedAtAfterRepositoryStorageMove, :sidekiq do
  let_it_be(:projects) { table(:projects) }
  let_it_be(:project_repository_storage_moves) { table(:project_repository_storage_moves) }
  let_it_be(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }

  describe '#up' do
    it 'schedules background jobs for all distinct projects in batches' do
      stub_const("#{described_class}::BATCH_SIZE", 3)

      project_1 = projects.create!(id: 1, namespace_id: namespace.id)
      project_2 = projects.create!(id: 2, namespace_id: namespace.id)
      project_3 = projects.create!(id: 3, namespace_id: namespace.id)
      project_4 = projects.create!(id: 4, namespace_id: namespace.id)
      project_5 = projects.create!(id: 5, namespace_id: namespace.id)
      project_6 = projects.create!(id: 6, namespace_id: namespace.id)
      project_7 = projects.create!(id: 7, namespace_id: namespace.id)
      projects.create!(id: 8, namespace_id: namespace.id)

      project_repository_storage_moves.create!(id: 1, project_id: project_1.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 2, project_id: project_1.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 3, project_id: project_2.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 4, project_id: project_3.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 5, project_id: project_3.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 6, project_id: project_4.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 7, project_id: project_4.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 8, project_id: project_5.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 9, project_id: project_6.id, source_storage_name: 'default', destination_storage_name: 'default')
      project_repository_storage_moves.create!(id: 10, project_id: project_7.id, source_storage_name: 'default', destination_storage_name: 'default')

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(3)
          expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(2.minutes, 1, 2, 3)
          expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(4.minutes, 4, 5, 6)
          expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(6.minutes, 7)
        end
      end
    end
  end
end
