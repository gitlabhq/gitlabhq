# frozen_string_literal: true

require 'spec_helper'
# this needs the schema to be before we introduce the not null constraint on routes#namespace_id
RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceIdForProjectRoute, schema: 20220606060825 do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:routes) { table(:routes) }

  let(:namespace1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let(:namespace2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: namespace1.id, path: 'space2') }
  let(:namespace3) { namespaces.create!(name: 'batchtest3', type: 'Group', parent_id: namespace2.id, path: 'space3') }

  let(:proj_namespace1) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id) }
  let(:proj_namespace2) { namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace2.id) }
  let(:proj_namespace3) { namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: namespace3.id) }
  let(:proj_namespace4) { namespaces.create!(name: 'proj4', path: 'proj4', type: 'Project', parent_id: namespace3.id) }

  # rubocop:disable Layout/LineLength
  let(:proj1) { projects.create!(name: 'proj1', path: 'proj1', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id) }
  let(:proj2) { projects.create!(name: 'proj2', path: 'proj2', namespace_id: namespace2.id, project_namespace_id: proj_namespace2.id) }
  let(:proj3) { projects.create!(name: 'proj3', path: 'proj3', namespace_id: namespace3.id, project_namespace_id: proj_namespace3.id) }
  let(:proj4) { projects.create!(name: 'proj4', path: 'proj4', namespace_id: namespace3.id, project_namespace_id: proj_namespace4.id) }
  # rubocop:enable Layout/LineLength

  let!(:namespace_route1) { routes.create!(path: 'space1', source_id: namespace1.id, source_type: 'Namespace') }
  let!(:namespace_route2) { routes.create!(path: 'space1/space2', source_id: namespace2.id, source_type: 'Namespace') }
  let!(:namespace_route3) { routes.create!(path: 'space1/space3', source_id: namespace3.id, source_type: 'Namespace') }

  let!(:proj_route1) { routes.create!(path: 'space1/proj1', source_id: proj1.id, source_type: 'Project') }
  let!(:proj_route2) { routes.create!(path: 'space1/space2/proj2', source_id: proj2.id, source_type: 'Project') }
  let!(:proj_route3) { routes.create!(path: 'space1/space3/proj3', source_id: proj3.id, source_type: 'Project') }
  let!(:proj_route4) { routes.create!(path: 'space1/space3/proj4', source_id: proj4.id, source_type: 'Project') }

  subject(:perform_migration) { migration.perform(proj_route1.id, proj_route4.id, :routes, :id, 2, 0) }

  it 'backfills namespace_id for the selected records', :aggregate_failures do
    perform_migration

    expected_namespaces = [proj_namespace1.id, proj_namespace2.id, proj_namespace3.id, proj_namespace4.id]

    expected_projects = [proj_route1.id, proj_route2.id, proj_route3.id, proj_route4.id]
    expect(routes.where.not(namespace_id: nil).pluck(:id)).to match_array(expected_projects)
    expect(routes.where.not(namespace_id: nil).pluck(:namespace_id)).to match_array(expected_namespaces)
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
