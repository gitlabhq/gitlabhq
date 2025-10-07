# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTodosWithMultipleColumnShardingKey, feature_category: :notifications do
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:user) do
    table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:group) do
    table(:namespaces).create!(name: 'name', path: 'path', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: group.id, namespace_id: group.id)
  end

  let(:issue_type) { table(:work_item_types).find_by(name: 'Issue') }
  let!(:issue) do
    table(:issues).create!(project_id: project.id, namespace_id: group.id, work_item_type_id: issue_type.id)
  end

  let(:todos) { table(:todos) }
  let(:migration_args) do
    {
      start_id: todos.minimum(:id),
      end_id: todos.maximum(:id),
      batch_table: :todos,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'sets group_id to NULL for rows where group_id IS NOT NULL and project_ID IS NOT NULL' do
    drop_constraint_and_trigger

    todo0 = todos.create!(
      action: 1,
      target_type: 'Issue',
      target_id: issue.id,
      author_id: user.id,
      state: 'pending',
      user_id: user.id,
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
    todo0.reload
    expect(todo0.organization_id).to be_nil
    expect(todo0.group_id).to be_nil
    expect(todo0.project_id).to be_nil

    todo1 = todos.create!(
      action: 1,
      target_type: 'Issue',
      target_id: issue.id,
      author_id: user.id,
      state: 'pending',
      user_id: user.id,
      organization_id: nil,
      group_id: group.id,
      project_id: project.id
    )
    todo1.reload
    expect(todo1.organization_id).to be_nil
    expect(todo1.group_id).to eq(group.id)
    expect(todo1.project_id).to eq(project.id)

    recreate_constraint_and_trigger

    todo2 = todos.create!(
      action: 1,
      target_type: 'Issue',
      target_id: issue.id,
      author_id: user.id,
      state: 'pending',
      user_id: user.id,
      organization_id: nil,
      group_id: nil,
      project_id: project.id
    )
    todo2.reload
    expect(todo2.organization_id).to be_nil
    expect(todo2.group_id).to be_nil
    expect(todo2.project_id).to eq(project.id)

    todo3 = todos.create!(
      action: 1,
      target_type: 'Issue',
      target_id: issue.id,
      author_id: user.id,
      state: 'pending',
      user_id: user.id,
      organization_id: nil,
      group_id: group.id,
      project_id: nil
    )
    todo3.reload
    expect(todo3.organization_id).to be_nil
    expect(todo3.group_id).to eq(group.id)
    expect(todo3.project_id).to be_nil

    todo4 = todos.create!(
      action: 15,
      target_type: 'Key',
      author_id: user.id,
      state: 'pending',
      user_id: user.id,
      organization_id: organization.id,
      group_id: nil,
      project_id: nil
    )
    todo4.reload
    expect(todo4.organization_id).to eq(organization.id)
    expect(todo4.group_id).to be_nil
    expect(todo4.project_id).to be_nil

    described_class.new(**migration_args).perform

    todo0.reload
    expect(todo0.organization_id).to eq(organization.id)
    expect(todo0.group_id).to be_nil
    expect(todo0.project_id).to be_nil

    todo1.reload
    expect(todo1.organization_id).to be_nil
    expect(todo1.group_id).to be_nil
    expect(todo1.project_id).to eq(project.id)

    todo2.reload
    expect(todo2.organization_id).to be_nil
    expect(todo2.group_id).to be_nil
    expect(todo2.project_id).to eq(project.id)

    todo3.reload
    expect(todo3.organization_id).to be_nil
    expect(todo3.group_id).to eq(group.id)
    expect(todo3.project_id).to be_nil

    todo4.reload
    expect(todo4.organization_id).to eq(organization.id)
    expect(todo4.group_id).to be_nil
    expect(todo4.project_id).to be_nil
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS trigger_todos_sharding_key ON todos;

        ALTER TABLE todos DROP CONSTRAINT IF EXISTS check_3c13ed1c7a;
      SQL
    )
  end

  def recreate_constraint_and_trigger
    connection.execute(
      <<~SQL
        CREATE TRIGGER trigger_todos_sharding_key BEFORE INSERT OR UPDATE
          ON todos FOR EACH ROW EXECUTE FUNCTION todos_sharding_key();

        ALTER TABLE todos
          ADD CONSTRAINT check_3c13ed1c7a CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
      SQL
    )
  end
end
