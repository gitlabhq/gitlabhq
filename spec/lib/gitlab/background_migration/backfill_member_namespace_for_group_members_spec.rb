# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMemberNamespaceForGroupMembers, :migration, schema: 20220120211832 do
  let(:migration) { described_class.new }
  let(:members_table) { table(:members) }
  let(:namespaces_table) { table(:namespaces) }

  let(:table_name) { 'members' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 100 }
  let(:pause_ms) { 0 }

  subject(:perform_migration) { migration.perform(1, 10, table_name, batch_column, sub_batch_size, pause_ms) }

  before do
    namespaces_table.create!(id: 100, name: 'test1', path: 'test1', type: 'Group')
    namespaces_table.create!(id: 101, name: 'test2', path: 'test2', type: 'Group')
    namespaces_table.create!(id: 102, name: 'test3', path: 'test3', type: 'Group')
    namespaces_table.create!(id: 201, name: 'test4', path: 'test4', type: 'Project')

    members_table.create!(id: 1, source_id: 100, source_type: 'Namespace', type: 'GroupMember', member_namespace_id: nil, access_level: 10, notification_level: 3)
    members_table.create!(id: 2, source_id: 101, source_type: 'Namespace', type: 'GroupMember', member_namespace_id: nil, access_level: 10, notification_level: 3)
    members_table.create!(id: 3, source_id: 102, source_type: 'Namespace', type: 'GroupMember', member_namespace_id: 102, access_level: 10, notification_level: 3)
    members_table.create!(id: 4, source_id: 103, source_type: 'Project', type: 'ProjectMember', member_namespace_id: nil, access_level: 10, notification_level: 3)
    members_table.create!(id: 5, source_id: 104, source_type: 'Project', type: 'ProjectMember', member_namespace_id: 201, access_level: 10, notification_level: 3)
  end

  it 'backfills `member_namespace_id` for the selected records', :aggregate_failures do
    expect(members_table.where(type: 'GroupMember', member_namespace_id: nil).count).to eq 2
    expect(members_table.where(type: 'ProjectMember', member_namespace_id: nil).count).to eq 1

    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(3)
    expect(members_table.where(type: 'GroupMember', member_namespace_id: nil).count).to eq 0
    expect(members_table.where(type: 'GroupMember').pluck(:member_namespace_id)).to match_array([100, 101, 102])
    expect(members_table.where(type: 'ProjectMember', member_namespace_id: nil).count).to eq 1
    expect(members_table.where(type: 'ProjectMember').pluck(:member_namespace_id)).to match_array([nil, 201])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
