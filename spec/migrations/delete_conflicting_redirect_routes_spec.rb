require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170907170235_delete_conflicting_redirect_routes')

describe DeleteConflictingRedirectRoutes, :migration, :sidekiq do
  let!(:redirect_routes) { table(:redirect_routes) }
  let!(:routes) { table(:routes) }

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
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

  # No-op. See https://gitlab.com/gitlab-com/infrastructure/issues/3460#note_53223252
  it 'NO-OP: does not schedule any background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq 0
      end
    end
  end
end
