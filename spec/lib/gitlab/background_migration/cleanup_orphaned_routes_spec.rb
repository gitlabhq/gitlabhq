# frozen_string_literal: true

require 'spec_helper'

# this needs the schema to be before we introduce the not null constraint on routes#namespace_id
RSpec.describe Gitlab::BackgroundMigration::CleanupOrphanedRoutes, schema: 20220606060825 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:routes) { table(:routes) }

  let!(:namespace1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let!(:namespace2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: namespace1.id, path: 'space2') }
  let!(:namespace3) { namespaces.create!(name: 'batchtest3', type: 'Group', parent_id: namespace2.id, path: 'space3') }

  let!(:proj_namespace1) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id) }
  let!(:proj_namespace2) { namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace2.id) }
  let!(:proj_namespace3) { namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: namespace3.id) }

  # rubocop:disable Layout/LineLength
  let!(:proj1) { projects.create!(name: 'proj1', path: 'proj1', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id) }
  let!(:proj2) { projects.create!(name: 'proj2', path: 'proj2', namespace_id: namespace2.id, project_namespace_id: proj_namespace2.id) }
  let!(:proj3) { projects.create!(name: 'proj3', path: 'proj3', namespace_id: namespace3.id, project_namespace_id: proj_namespace3.id) }

  # valid namespace routes with not null namespace_id
  let!(:namespace_route1) { routes.create!(path: 'space1', source_id: namespace1.id, source_type: 'Namespace', namespace_id: namespace1.id) }
  # valid namespace routes with null namespace_id
  let!(:namespace_route2) { routes.create!(path: 'space1/space2', source_id: namespace2.id, source_type: 'Namespace') }
  let!(:namespace_route3) { routes.create!(path: 'space1/space3', source_id: namespace3.id, source_type: 'Namespace') }
  # invalid/orphaned namespace route
  let!(:orphaned_namespace_route_a) { routes.create!(path: 'space1/space4', source_id: non_existing_record_id, source_type: 'Namespace') }
  let!(:orphaned_namespace_route_b) { routes.create!(path: 'space1/space5', source_id: non_existing_record_id - 1, source_type: 'Namespace') }

  # valid project routes with not null namespace_id
  let!(:proj_route1) { routes.create!(path: 'space1/proj1', source_id: proj1.id, source_type: 'Project', namespace_id: proj_namespace1.id) }
  # valid project routes with null namespace_id
  let!(:proj_route2) { routes.create!(path: 'space1/space2/proj2', source_id: proj2.id, source_type: 'Project') }
  let!(:proj_route3) { routes.create!(path: 'space1/space3/proj3', source_id: proj3.id, source_type: 'Project') }
  # invalid/orphaned namespace route
  let!(:orphaned_project_route_a) { routes.create!(path: 'space1/space3/proj5', source_id: non_existing_record_id, source_type: 'Project') }
  let!(:orphaned_project_route_b) { routes.create!(path: 'space1/space3/proj6', source_id: non_existing_record_id - 1, source_type: 'Project') }
  # rubocop:enable Layout/LineLength

  let!(:migration_attrs) do
    {
      start_id: Route.minimum(:id),
      end_id: Route.maximum(:id),
      batch_table: :routes,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  subject(:perform_migration) { migration.perform }

  it 'cleans orphaned routes', :aggregate_failures do
    all_route_ids = Route.pluck(:id)

    orphaned_route_ids = [
      orphaned_namespace_route_a, orphaned_namespace_route_b, orphaned_project_route_a, orphaned_project_route_b
    ].pluck(:id)
    remaining_routes = (all_route_ids - orphaned_route_ids).sort

    expect { perform_migration }.to change { Route.pluck(:id) }.to contain_exactly(*remaining_routes)
    expect(Route.all).to all(have_attributes(namespace_id: be_present))

    # expect that routes that had namespace_id set did not change namespace_id
    expect(namespace_route1.reload.namespace_id).to eq(namespace1.id)
    expect(proj_route1.reload.namespace_id).to eq(proj_namespace1.id)
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
