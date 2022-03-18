# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigratePersonalNamespaceProjectMaintainerToOwner, :migration, schema: 20220208080921 do
  let(:migration) { described_class.new }
  let(:users_table) { table(:users) }
  let(:members_table) { table(:members) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }

  let(:table_name) { 'members' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 10 }
  let(:pause_ms) { 0 }

  let(:owner_access) { 50 }
  let(:maintainer_access) { 40 }
  let(:developer_access) { 30 }

  subject(:perform_migration) { migration.perform(1, 10, table_name, batch_column, sub_batch_size, pause_ms) }

  before do
    users_table.create!(id: 101, name: "user1", email: "user1@example.com", projects_limit: 5)
    users_table.create!(id: 102, name: "user2", email: "user2@example.com", projects_limit: 5)

    namespaces_table.create!(id: 201, name: 'user1s-namespace', path: 'user1s-namespace-path', type: 'User', owner_id: 101)
    namespaces_table.create!(id: 202, name: 'user2s-namespace', path: 'user2s-namespace-path', type: 'User', owner_id: 102)
    namespaces_table.create!(id: 203, name: 'group', path: 'group', type: 'Group')
    namespaces_table.create!(id: 204, name: 'project-namespace', path: 'project-namespace-path', type: 'Project')

    projects_table.create!(id: 301, name: 'user1-namespace-project', path: 'project-path-1', namespace_id: 201)
    projects_table.create!(id: 302, name: 'user2-namespace-project', path: 'project-path-2', namespace_id: 202)
    projects_table.create!(id: 303, name: 'user2s-namespace-project2', path: 'project-path-3', namespace_id: 202)
    projects_table.create!(id: 304, name: 'group-project3', path: 'group-project-path-3', namespace_id: 203)

    # user1 member of their own namespace project, maintainer access (change)
    create_project_member(id: 1, user_id: 101, project_id: 301, level: maintainer_access)

    # user2 member of their own namespace project, owner access (no change)
    create_project_member(id: 2, user_id: 102, project_id: 302, level: owner_access)

    # user1 member of user2's personal namespace project, maintainer access (no change)
    create_project_member(id: 3, user_id: 101, project_id: 302, level: maintainer_access)

    # user1 member of group project, maintainer access (no change)
    create_project_member(id: 4, user_id: 101, project_id: 304, level: maintainer_access)

    # user1 member of group, Maintainer role (no change)
    create_group_member(id: 5, user_id: 101, group_id: 203, level: maintainer_access)

    # user2 member of their own namespace project, maintainer access, but out of batch range (no change)
    create_project_member(id: 601, user_id: 102, project_id: 303, level: maintainer_access)
  end

  it 'migrates MAINTAINER membership records for personal namespaces to OWNER', :aggregate_failures do
    expect(members_table.where(access_level: owner_access).count).to eq 1
    expect(members_table.where(access_level: maintainer_access).count).to eq 5

    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(3)
    expect(members_table.where(access_level: owner_access).pluck(:id)).to match_array([1, 2])
    expect(members_table.where(access_level: maintainer_access).pluck(:id)).to match_array([3, 4, 5, 601])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end

  def create_group_member(id:, user_id:, group_id:, level:)
    members_table.create!(id: id, user_id: user_id, source_id: group_id, access_level: level, source_type: "Namespace", type: "GroupMember", notification_level: 3)
  end

  def create_project_member(id:, user_id:, project_id:, level:)
    members_table.create!(id: id, user_id: user_id, source_id: project_id, access_level: level, source_type: "Namespace", type: "ProjectMember", notification_level: 3)
  end
end
