# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210604070207_retry_backfill_traversal_ids.rb')

RSpec.describe RetryBackfillTraversalIds, :migration do
  include ReloadHelpers

  let_it_be(:namespaces_table) { table(:namespaces) }

  context 'when BackfillNamespaceTraversalIdsRoots jobs are pending' do
    before do
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsRoots',
        arguments: [1, 4, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsRoots',
        arguments: [5, 9, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
    end

    it 'queues pending jobs' do
      migrate!

      expect(BackgroundMigrationWorker.jobs.length).to eq(1)
      expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['BackfillNamespaceTraversalIdsRoots', [1, 4, 100]])
      expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
    end
  end

  context 'when BackfillNamespaceTraversalIdsChildren jobs are pending' do
    before do
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsChildren',
        arguments: [1, 4, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsRoots',
        arguments: [5, 9, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
    end

    it 'queues pending jobs' do
      migrate!

      expect(BackgroundMigrationWorker.jobs.length).to eq(1)
      expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['BackfillNamespaceTraversalIdsChildren', [1, 4, 100]])
      expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
    end
  end

  context 'when BackfillNamespaceTraversalIdsRoots and BackfillNamespaceTraversalIdsChildren jobs are pending' do
    before do
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsRoots',
        arguments: [1, 4, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsChildren',
        arguments: [5, 9, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsRoots',
        arguments: [11, 14, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
      table(:background_migration_jobs).create!(
        class_name: 'BackfillNamespaceTraversalIdsChildren',
        arguments: [15, 19, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
    end

    it 'queues pending jobs' do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.length).to eq(2)
        expect(BackgroundMigrationWorker.jobs[0]['args']).to eq(['BackfillNamespaceTraversalIdsRoots', [1, 4, 100]])
        expect(BackgroundMigrationWorker.jobs[0]['at']).to be_nil
        expect(BackgroundMigrationWorker.jobs[1]['args']).to eq(['BackfillNamespaceTraversalIdsChildren', [5, 9, 100]])
        expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(RetryBackfillTraversalIds::DELAY_INTERVAL.from_now.to_f)
      end
    end
  end
end
