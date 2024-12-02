# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- We need this many for this background migration
RSpec.describe Gitlab::BackgroundMigration::ProjectBotUserDetailsBotNamespaceMigration, feature_category: :system_access do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:members) { table(:members) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }
  let(:subgroup) { namespaces.create!(name: 'subgroup', path: 'sub', type: 'Group', organization_id: organization.id) }
  let(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group', organization_id: organization.id) }

  let(:project_namespace) do
    namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      organization_id: organization.id,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      name: 'proj1',
      path: 'proj1'
    )
  end

  let!(:project_bot1) do
    users.create!(username: 'project_bot', email: 'project_bot@example.com', user_type: 6, projects_limit: 10)
  end

  let!(:project_bot2) do
    users.create!(username: 'group_bot2', email: 'group_bot2@example.com', user_type: 6, projects_limit: 10)
  end

  let!(:project_bot3) do
    users.create!(username: 'project_bot3', email: 'project_bot3@example.com', user_type: 6, projects_limit: 10)
  end

  let!(:project_bot4) do
    users.create!(username: 'group_bot4', email: 'group_bot4@example.com', user_type: 6, projects_limit: 10)
  end

  let!(:orphaned_project_bot) do
    users.create!(username: 'group_bot5', email: 'group_bot5@example.com', user_type: 6, projects_limit: 10)
  end

  let!(:regular_user) do
    users.create!(username: 'john_doe', email: 'john_doe@example.com', user_type: 0, projects_limit: 10)
  end

  let!(:regular_user2) do
    users.create!(username: 'jane_doe', email: 'jane_doe@example.com', user_type: 0, projects_limit: 10)
  end

  let!(:project_bot1_details) { user_details.create!(user_id: project_bot1.id) }
  let!(:project_bot2_details) { user_details.create!(user_id: project_bot2.id) }
  let!(:project_bot3_details) { user_details.create!(user_id: project_bot3.id) }
  let!(:project_bot4_details) { user_details.create!(user_id: project_bot4.id) }
  let!(:orphaned_project_bot_details) { user_details.create!(user_id: orphaned_project_bot.id) }
  let!(:regular_user_details) { user_details.create!(user_id: regular_user.id) }
  let!(:regular_user2_details) { user_details.create!(user_id: regular_user2.id) }

  let!(:start_id) { users.minimum(:id) }
  let!(:end_id) { users.maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 2,
      job_arguments: [nil],
      connection: ApplicationRecord.connection
    )
  end

  before do
    members.create!(access_level: 50, source_id: project.id, source_type: "Project", user_id: project_bot1.id, state: 0,
      type: "ProjectMember", member_namespace_id: project_namespace.id, notification_level: 3)
    members.create!(access_level: 30, source_id: group.id, source_type: "Namespace", user_id: project_bot2.id, state: 0,
      type: "GroupMember", member_namespace_id: group.id, notification_level: 3)
    members.create!(access_level: 50, source_id: subgroup.id, source_type: "Namespace", user_id: project_bot3.id,
      state: 0, type: "GroupMember", member_namespace_id: subgroup.id, notification_level: 3)
    members.create!(access_level: 30, source_id: group2.id, source_type: "Namespace", user_id: project_bot4.id,
      state: 0, type: "GroupMember", member_namespace_id: group2.id, notification_level: 3)
    members.create!(access_level: 30, source_id: group.id, source_type: "Namespace", user_id: regular_user.id, state: 0,
      type: "GroupMember", member_namespace_id: group.id, notification_level: 3)
    members.create!(access_level: 30, source_id: group2.id, source_type: "Namespace", user_id: regular_user2.id,
      state: 0, type: "GroupMember", member_namespace_id: group2.id, notification_level: 3)
  end

  it 'populates bot_namespace_id correctly' do
    migration.perform

    expect(project_bot1_details.reload.bot_namespace_id).to eq(project_namespace.id)
    expect(project_bot2_details.reload.bot_namespace_id).to eq(group.id)
    expect(project_bot3_details.reload.bot_namespace_id).to eq(subgroup.id)
    expect(project_bot4_details.reload.bot_namespace_id).to eq(group2.id)
    expect(orphaned_project_bot_details.reload.bot_namespace_id).to be_nil
    expect(regular_user_details.reload.bot_namespace_id).to be_nil
    expect(regular_user2_details.reload.bot_namespace_id).to be_nil
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
