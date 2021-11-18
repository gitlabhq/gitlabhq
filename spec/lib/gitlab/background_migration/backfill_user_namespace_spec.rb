# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserNamespace, :migration, schema: 20210930211936 do
  let(:migration) { described_class.new }
  let(:namespaces_table) { table(:namespaces) }

  let(:table_name) { 'namespaces' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 100 }
  let(:pause_ms) { 0 }

  subject(:perform_migration) { migration.perform(1, 10, table_name, batch_column, sub_batch_size, pause_ms) }

  before do
    namespaces_table.create!(id: 1, name: 'test1', path: 'test1', type: nil)
    namespaces_table.create!(id: 2, name: 'test2', path: 'test2', type: 'User')
    namespaces_table.create!(id: 3, name: 'test3', path: 'test3', type: 'Group')
    namespaces_table.create!(id: 4, name: 'test4', path: 'test4', type: nil)
    namespaces_table.create!(id: 11, name: 'test11', path: 'test11', type: nil)
  end

  it 'backfills `type` for the selected records', :aggregate_failures do
    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(3)
    expect(namespaces_table.where(type: 'User').count).to eq 3
    expect(namespaces_table.where(type: 'User').pluck(:id)).to match_array([1, 2, 4])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
