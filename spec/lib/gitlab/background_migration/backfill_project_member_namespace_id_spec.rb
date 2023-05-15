# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectMemberNamespaceId, :migration, schema: 20220516054011 do
  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 10,
      batch_table: table_name, batch_column: batch_column,
      sub_batch_size: sub_batch_size, pause_ms: pause_ms,
      connection: ApplicationRecord.connection
    )
  end

  let(:members_table) { table(:members) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }

  let(:table_name) { 'members' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 100 }
  let(:pause_ms) { 0 }

  subject(:perform_migration) do
    migration.perform
  end

  before do
    namespaces_table.create!(id: 201, name: 'group1', path: 'group1', type: 'Group')
    namespaces_table.create!(id: 202, name: 'group2', path: 'group2', type: 'Group')
    namespaces_table.create!(id: 300, name: 'project-namespace-1', path: 'project-namespace-1-path', type: 'Project')
    namespaces_table.create!(id: 301, name: 'project-namespace-2', path: 'project-namespace-2-path', type: 'Project')
    namespaces_table.create!(id: 302, name: 'project-namespace-3', path: 'project-namespace-3-path', type: 'Project')

    projects_table.create!(id: 100, name: 'project1', path: 'project1', namespace_id: 202, project_namespace_id: 300)
    projects_table.create!(id: 101, name: 'project2', path: 'project2', namespace_id: 202, project_namespace_id: 301)
    projects_table.create!(id: 102, name: 'project3', path: 'project3', namespace_id: 202, project_namespace_id: 302)

    # project1, no member namespace (fill in)
    members_table.create!(
      id: 1, source_id: 100,
      source_type: 'Project', type: 'ProjectMember',
      member_namespace_id: nil, access_level: 10, notification_level: 3
    )

    # bogus source id, no member namespace id (do nothing)
    members_table.create!(
      id: 2, source_id: non_existing_record_id,
      source_type: 'Project', type: 'ProjectMember',
      member_namespace_id: nil, access_level: 10, notification_level: 3
    )

    # project3, existing member namespace id (do nothing)
    members_table.create!(
      id: 3, source_id: 102,
      source_type: 'Project', type: 'ProjectMember',
      member_namespace_id: 300, access_level: 10, notification_level: 3
    )

    # Group memberships (do not change)
    # group1, no member namespace (do nothing)
    members_table.create!(
      id: 4, source_id: 201,
      source_type: 'Namespace', type: 'GroupMember',
      member_namespace_id: nil, access_level: 10, notification_level: 3
    )

    # group2, existing member namespace (do nothing)
    members_table.create!(
      id: 5, source_id: 202,
      source_type: 'Namespace', type: 'GroupMember',
      member_namespace_id: 201, access_level: 10, notification_level: 3
    )

    # Project Namespace memberships (do not change)
    # project namespace, existing member namespace (do nothing)
    members_table.create!(
      id: 6, source_id: 300,
      source_type: 'Namespace', type: 'ProjectNamespaceMember',
      member_namespace_id: 201, access_level: 10, notification_level: 3
    )

    # project namespace, not member namespace (do nothing)
    members_table.create!(
      id: 7, source_id: 301,
      source_type: 'Namespace', type: 'ProjectNamespaceMember',
      member_namespace_id: 201, access_level: 10, notification_level: 3
    )
  end

  it 'backfills `member_namespace_id` for the selected records', :aggregate_failures do
    expect(members_table.where(type: 'ProjectMember', member_namespace_id: nil).count).to eq 2
    expect(members_table.where(type: 'GroupMember', member_namespace_id: nil).count).to eq 1

    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    # rubocop:disable Layout/LineLength
    expect(queries.count).to eq(3)
    expect(members_table.where(type: 'ProjectMember', member_namespace_id: nil).count).to eq 1 # just the bogus one
    expect(members_table.where(type: 'ProjectMember').pluck(:member_namespace_id)).to match_array([nil, 300, 300])
    expect(members_table.where(type: 'GroupMember', member_namespace_id: nil).count).to eq 1
    expect(members_table.where(type: 'GroupMember').pluck(:member_namespace_id)).to match_array([nil, 201])
    # rubocop:enable Layout/LineLength
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end

  context 'when given a negative pause_ms' do
    let(:pause_ms) { -9 }
    let(:sub_batch_size) { 2 }

    it 'uses 0 as a floor for pause_ms' do
      expect(migration).to receive(:sleep).with(0)

      perform_migration
    end
  end
end
