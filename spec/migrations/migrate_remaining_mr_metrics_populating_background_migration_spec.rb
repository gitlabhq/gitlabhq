require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180521162137_migrate_remaining_mr_metrics_populating_background_migration.rb')

describe MigrateRemainingMrMetricsPopulatingBackgroundMigration, :migration, :sidekiq do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:mrs) { table(:merge_requests) }

  before do
    namespaces.create!(id: 1, name: 'foo', path: 'foo')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 1)
    projects.create!(id: 456, name: 'gitlab2', path: 'gitlab2', namespace_id: 1)
    projects.create!(id: 789, name: 'gitlab3', path: 'gitlab3', namespace_id: 1)
    mrs.create!(title: 'foo', target_branch: 'target', source_branch: 'source', target_project_id: 123)
    mrs.create!(title: 'bar', target_branch: 'target', source_branch: 'source', target_project_id: 456)
    mrs.create!(title: 'kux', target_branch: 'target', source_branch: 'source', target_project_id: 789)
  end

  it 'correctly schedules background migrations' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(10.minutes, mrs.first.id, mrs.second.id)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(20.minutes, mrs.third.id, mrs.third.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
