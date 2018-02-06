require 'spec_helper'

describe Gitlab::BackgroundMigration::DeleteConflictingRedirectRoutesRange, :migration, schema: 20170907170235 do
  let!(:redirect_routes) { table(:redirect_routes) }
  let!(:routes) { table(:routes) }

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
  it 'NO-OP: does not delete any redirect_routes' do
    expect(redirect_routes.count).to eq(8)

    described_class.new.perform(1, 5)

    expect(redirect_routes.count).to eq(8)
  end
end
