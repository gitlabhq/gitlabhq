# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DestroyInvalidProjectMembers, :migration, schema: 20220901035725 do
  # rubocop: disable Layout/LineLength
  # rubocop: disable RSpec/ScatteredLet
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

  let!(:migration) { described_class.new(**migration_attrs) }

  subject(:perform_migration) { migration.perform }

  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:members_table) { table(:members) }
  let(:projects_table) { table(:projects) }

  let(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 5) }
  let(:user2) { users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 5) }
  let(:user3) { users_table.create!(name: 'user3', email: 'user3@example.com', projects_limit: 5) }
  let(:user4) { users_table.create!(name: 'user4', email: 'user4@example.com', projects_limit: 5) }
  let(:user5) { users_table.create!(name: 'user5', email: 'user5@example.com', projects_limit: 5) }
  let(:user6) { users_table.create!(name: 'user6', email: 'user6@example.com', projects_limit: 5) }

  let!(:group1) { namespaces_table.create!(name: 'marvellous group 1', path: 'group-path-1', type: 'Group') }

  let!(:project_namespace1) do
    namespaces_table.create!(name: 'fabulous project', path: 'project-path-1', type: 'ProjectNamespace',
                             parent_id: group1.id)
  end

  let!(:project1) do
    projects_table.create!(name: 'fabulous project', path: 'project-path-1', project_namespace_id: project_namespace1.id,
                           namespace_id: group1.id)
  end

  let!(:project_namespace2) do
    namespaces_table.create!(name: 'splendiferous project', path: 'project-path-2', type: 'ProjectNamespace',
                             parent_id: group1.id)
  end

  let!(:project2) do
    projects_table.create!(name: 'splendiferous project', path: 'project-path-2', project_namespace_id: project_namespace2.id,
                           namespace_id: group1.id)
  end

  # create project member records, a mix of both valid and invalid
  # group members will have already been filtered out.
  let!(:project_member1) { create_invalid_project_member(id: 1, user_id: user1.id) }
  let!(:project_member2) { create_valid_project_member(id: 4, user_id: user2.id, project: project1) }
  let!(:project_member3) { create_valid_project_member(id: 5, user_id: user3.id, project: project2) }
  let!(:project_member4) { create_invalid_project_member(id: 6, user_id: user4.id) }
  let!(:project_member5) { create_valid_project_member(id: 7, user_id: user5.id, project: project2) }
  let!(:project_member6) { create_invalid_project_member(id: 8, user_id: user6.id) }

  it 'removes invalid memberships but keeps valid ones', :aggregate_failures do
    expect(members_table.where(type: 'ProjectMember').count).to eq 6

    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(4)
    expect(members_table.where(type: 'ProjectMember')).to match_array([project_member2, project_member3, project_member5])
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end

  it 'logs IDs of deleted records' do
    expect(Gitlab::AppLogger).to receive(:info).with({ message: 'Removing invalid project member records',
                                                       deleted_count: 3, ids: [project_member1, project_member4, project_member6].map(&:id) })

    perform_migration
  end

  def create_invalid_project_member(id:, user_id:)
    members_table.create!(id: id, user_id: user_id, source_id: non_existing_record_id, access_level: Gitlab::Access::MAINTAINER,
                          type: "ProjectMember", source_type: "Project", notification_level: 3, member_namespace_id: nil)
  end

  def create_valid_project_member(id:, user_id:, project:)
    members_table.create!(id: id, user_id: user_id, source_id: project.id, access_level: Gitlab::Access::MAINTAINER,
                          type: "ProjectMember", source_type: "Project", member_namespace_id: project.project_namespace_id, notification_level: 3)
  end
  # rubocop: enable Layout/LineLength
  # rubocop: enable RSpec/ScatteredLet
end
