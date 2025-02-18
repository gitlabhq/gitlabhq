# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::BackgroundMigration::DestroyInvalidMembers, :migration, schema: 20231220225325 do
  let!(:migration_attrs) do
    {
      start_id: 1,
      end_id: 1000,
      batch_table: :members,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:users_table) { table(:users) }
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:members_table) { table(:members) }
  let(:projects_table) { table(:projects) }
  let(:members_table_name) { 'members' }
  let(:connection) { ApplicationRecord.connection }
  let(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 5) }
  let(:user2) { users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 5) }
  let(:user3) { users_table.create!(name: 'user3', email: 'user3@example.com', projects_limit: 5) }
  let(:user4) { users_table.create!(name: 'user4', email: 'user4@example.com', projects_limit: 5) }
  let(:user5) { users_table.create!(name: 'user5', email: 'user5@example.com', projects_limit: 5) }
  let(:user6) { users_table.create!(name: 'user6', email: 'user6@example.com', projects_limit: 5) }
  let(:user7) { users_table.create!(name: 'user7', email: 'user7@example.com', projects_limit: 5) }
  let(:user8) { users_table.create!(name: 'user8', email: 'user8@example.com', projects_limit: 5) }
  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }

  let!(:group1) do
    namespaces_table.create!(name: 'group 1', path: 'group-path-1', type: 'Group', organization_id: organization.id)
  end

  let!(:group2) do
    namespaces_table.create!(name: 'group 2', path: 'group-path-2', type: 'Group', organization_id: organization.id)
  end

  let!(:project_namespace1) do
    namespaces_table.create!(
      name: 'fabulous project',
      path: 'project-path-1',
      type: 'ProjectNamespace',
      parent_id: group1.id,
      organization_id: organization.id
    )
  end

  let!(:project1) do
    projects_table.create!(
      name: 'fabulous project',
      path: 'project-path-1',
      project_namespace_id: project_namespace1.id,
      namespace_id: group1.id,
      organization_id: organization.id
    )
  end

  let!(:project_namespace2) do
    namespaces_table.create!(
      name: 'splendiferous project',
      path: 'project-path-2',
      type: 'ProjectNamespace',
      parent_id: group1.id,
      organization_id: organization.id
    )
  end

  let!(:project2) do
    projects_table.create!(
      name: 'splendiferous project',
      path: 'project-path-2',
      project_namespace_id: project_namespace2.id,
      namespace_id: group1.id,
      organization_id: organization.id
    )
  end

  # create valid project member records
  let!(:project_member1) { create_valid_project_member(id: 1, user_id: user1.id, project: project1) }
  let!(:project_member2) { create_valid_project_member(id: 2, user_id: user2.id, project: project2) }
  # create valid group member records
  let!(:group_member5) { create_valid_group_member(id: 5, user_id: user5.id, group_id: group1.id) }
  let!(:group_member6) { create_valid_group_member(id: 6, user_id: user6.id, group_id: group2.id) }

  let!(:migration) { described_class.new(**migration_attrs) }

  subject(:perform_migration) { migration.perform }

  # create invalid project and group member records
  def create_members
    [
      create_invalid_project_member(id: 3, user_id: user3.id),
      create_invalid_project_member(id: 4, user_id: user4.id),
      create_invalid_group_member(id: 7, user_id: user7.id),
      create_invalid_group_member(id: 8, user_id: user8.id)
    ]
  end

  it 'removes invalid memberships but keeps valid ones', :aggregate_failures do
    without_check_constraint(members_table_name, 'check_508774aac0', connection: connection) do
      create_members

      expect(members_table.count).to eq 8

      queries = ActiveRecord::QueryRecorder.new do
        perform_migration
      end

      expect(queries.count).to eq(4)
      expect(members_table.all).to match_array([project_member1, project_member2, group_member5, group_member6])
    end
  end

  it 'tracks timings of queries' do
    without_check_constraint(members_table_name, 'check_508774aac0', connection: connection) do
      create_members

      expect(migration.batch_metrics.timings).to be_empty

      expect { perform_migration }.to change { migration.batch_metrics.timings }
    end
  end

  it 'logs IDs of deleted records' do
    without_check_constraint(members_table_name, 'check_508774aac0', connection: connection) do
      members = create_members

      member_data = members.map do |m|
        { id: m.id, source_id: m.source_id, source_type: m.source_type, access_level: m.access_level }
      end

      expect(Gitlab::AppLogger).to receive(:info).with({ message: 'Removing invalid member records',
                                                         deleted_count: 4,
                                                         deleted_member_data: match_array(member_data) })

      perform_migration
    end
  end

  def create_invalid_project_member(id:, user_id:)
    members_table.create!(
      id: id,
      user_id: user_id,
      source_id: non_existing_record_id,
      access_level: Gitlab::Access::MAINTAINER,
      type: "ProjectMember",
      source_type: "Project",
      notification_level: 3,
      member_namespace_id: nil
    )
  end

  def create_valid_project_member(id:, user_id:, project:)
    members_table.create!(
      id: id,
      user_id: user_id,
      source_id: project.id,
      access_level: Gitlab::Access::MAINTAINER,
      type: "ProjectMember",
      source_type: "Project",
      member_namespace_id: project.project_namespace_id,
      notification_level: 3
    )
  end

  def create_invalid_group_member(id:, user_id:)
    members_table.create!(
      id: id,
      user_id: user_id,
      source_id: non_existing_record_id,
      access_level: Gitlab::Access::MAINTAINER,
      type: "GroupMember",
      source_type: "Namespace",
      notification_level: 3,
      member_namespace_id: nil
    )
  end

  def create_valid_group_member(id:, user_id:, group_id:)
    members_table.create!(
      id: id,
      user_id: user_id,
      source_id: group_id,
      access_level: Gitlab::Access::MAINTAINER,
      type: "GroupMember",
      source_type: "Namespace",
      member_namespace_id: group_id,
      notification_level: 3
    )
  end
end
# rubocop: enable RSpec/MultipleMemoizedHelpers
