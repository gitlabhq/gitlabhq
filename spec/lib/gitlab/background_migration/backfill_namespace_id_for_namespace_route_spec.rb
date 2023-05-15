# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceIdForNamespaceRoute, :migration, schema: 20220120123800 do
  let(:migration) { described_class.new }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:routes_table) { table(:routes) }

  let(:table_name) { 'routes' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 200 }
  let(:pause_ms) { 0 }

  let(:namespace1) { namespaces_table.create!(name: 'namespace1', path: 'namespace1', type: 'User') }
  let(:namespace2) { namespaces_table.create!(name: 'namespace2', path: 'namespace2', type: 'Group') }
  let(:namespace3) { namespaces_table.create!(name: 'namespace3', path: 'namespace3', type: 'Group') }
  let(:namespace4) { namespaces_table.create!(name: 'namespace4', path: 'namespace4', type: 'Group') }
  let(:project1) { projects_table.create!(name: 'project1', namespace_id: namespace1.id) }

  subject(:perform_migration) { migration.perform(1, 10, table_name, batch_column, sub_batch_size, pause_ms) }

  before do
    routes_table.create!(
      id: 1, name: 'test1', path: 'test1', source_id: namespace1.id, source_type: namespace1.class.sti_name
    )

    routes_table.create!(
      id: 2, name: 'test2', path: 'test2', source_id: namespace2.id, source_type: namespace2.class.sti_name
    )

    routes_table.create!(
      id: 5, name: 'test3', path: 'test3', source_id: project1.id, source_type: project1.class.sti_name
    ) # should be ignored - project route

    routes_table.create!(
      id: 6, name: 'test4', path: 'test4', source_id: non_existing_record_id, source_type: namespace3.class.sti_name
    ) # should be ignored - invalid source_id

    routes_table.create!(
      id: 10, name: 'test5', path: 'test5', source_id: namespace3.id, source_type: namespace3.class.sti_name
    )

    routes_table.create!(
      id: 11, name: 'test6', path: 'test6', source_id: namespace4.id, source_type: namespace4.class.sti_name
    ) # should be ignored - outside the scope
  end

  it 'backfills `type` for the selected records', :aggregate_failures do
    perform_migration

    expect(routes_table.where.not(namespace_id: nil).pluck(:id)).to match_array([1, 2, 10])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
