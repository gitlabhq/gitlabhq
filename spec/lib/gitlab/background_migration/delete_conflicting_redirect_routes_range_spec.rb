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

  it 'deletes the conflicting redirect_routes in the range' do
    expect(redirect_routes.count).to eq(8)

    expect do
      described_class.new.perform(1, 3)
    end.to change { redirect_routes.where("path like 'foo%'").count }.from(5).to(2)

    expect do
      described_class.new.perform(4, 5)
    end.to change { redirect_routes.where("path like 'foo%'").count }.from(2).to(0)

    expect(redirect_routes.count).to eq(3)
  end
end
