require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180605124335_rebuild_trigram_indexes')

describe RebuildTrigramIndexes, :migration, :sidekiq, if: Gitlab::Database.postgresql? do
  it 'correctly schedules the background migrations' do
    Sidekiq::Testing.fake! do
      migrate!

      RebuildTrigramIndexes.trigram_indexes.each do |(table, column)|
        expect(Gitlab::BackgroundMigration::RebuildTrigramIndex).to be_scheduled_migration(table.to_s, column.to_s)
      end
      expect(BackgroundMigrationWorker.jobs.size).to eq(RebuildTrigramIndexes.trigram_indexes.size)
    end
  end
end
