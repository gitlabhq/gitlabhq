require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170907170235_delete_conflicting_redirect_routes')

describe DeleteConflictingRedirectRoutes, :migration, :sidekiq do
  let!(:redirect_routes) { table(:redirect_routes) }
  let!(:routes) { table(:routes) }

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    stub_const("DeleteConflictingRedirectRoutes::BATCH_SIZE", 2)
    stub_const("Gitlab::Database::MigrationHelpers::BACKGROUND_MIGRATION_JOB_BUFFER_SIZE", 2)

    routes.create!(id: 1, source_id: 1, source_type: 'Namespace', path: 'foo1')
    routes.create!(id: 2, source_id: 2, source_type: 'Namespace', path: 'foo2')
    routes.create!(id: 3, source_id: 3, source_type: 'Namespace', path: 'foo3')
    routes.create!(id: 4, source_id: 4, source_type: 'Namespace', path: 'foo4')
    routes.create!(id: 5, source_id: 5, source_type: 'Namespace', path: 'foo5')

    # Valid redirects
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'bar')
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'bar2')
    redirect_routes.create!(source_id: 2, source_type: 'Namespace', path: 'bar3')

    # Conflicting redirects
    redirect_routes.create!(source_id: 2, source_type: 'Namespace', path: 'foo1')
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'foo2')
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'foo3')
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'foo4')
    redirect_routes.create!(source_id: 1, source_type: 'Namespace', path: 'foo5')
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([described_class::MIGRATION, [1, 2]])
        expect(BackgroundMigrationWorker.jobs[0]['at']).to eq(12.seconds.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([described_class::MIGRATION, [3, 4]])
        expect(BackgroundMigrationWorker.jobs[1]['at']).to eq(24.seconds.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs[2]['args']).to eq([described_class::MIGRATION, [5, 5]])
        expect(BackgroundMigrationWorker.jobs[2]['at']).to eq(36.seconds.from_now.to_f)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.inline! do
      expect do
        migrate!
      end.to change { redirect_routes.count }.from(8).to(3)
    end
  end
end
