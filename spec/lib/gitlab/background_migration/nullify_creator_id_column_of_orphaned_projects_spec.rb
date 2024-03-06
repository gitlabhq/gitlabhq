# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyCreatorIdColumnOfOrphanedProjects,
  feature_category: :groups_and_projects do
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let(:user_1) { users.create!(name: 'user_1', email: 'user_1@example.com', projects_limit: 4) }
  let(:user_2) { users.create!(name: 'user_2', email: 'user_2@example.com', projects_limit: 4) }
  let(:user_3) { users.create!(name: 'user_3', email: 'user_3@example.com', projects_limit: 4) }

  let!(:group) do
    namespaces.create!(
      name: 'Group1', type: 'Group', path: 'space1'
    )
  end

  let!(:project_namespace_1) do
    namespaces.create!(
      name: 'project_1', path: 'project_1', type: 'Project'
    )
  end

  let!(:project_namespace_2) do
    namespaces.create!(
      name: 'project_2', path: 'project_2', type: 'Project'
    )
  end

  let!(:project_namespace_3) do
    namespaces.create!(
      name: 'project_3', path: 'project_3', type: 'Project'
    )
  end

  let!(:project_namespace_4) do
    namespaces.create!(
      name: 'project_4', path: 'project_4', type: 'Project'
    )
  end

  let!(:project_1) do
    projects.create!(
      name: 'project_1', path: 'project_1', namespace_id: group.id, project_namespace_id: project_namespace_1.id,
      creator_id: user_1.id
    )
  end

  let!(:project_2) do
    projects.create!(
      name: 'project_2', path: 'project_2', namespace_id: group.id, project_namespace_id: project_namespace_2.id,
      creator_id: user_2.id
    )
  end

  let!(:project_3) do
    projects.create!(
      name: 'project_3', path: 'project_3', namespace_id: group.id, project_namespace_id: project_namespace_3.id,
      creator_id: user_3.id
    )
  end

  let!(:project_4) do
    projects.create!(
      name: 'project_4', path: 'project_4', namespace_id: group.id, project_namespace_id: project_namespace_4.id,
      creator_id: nil
    )
  end

  subject do
    described_class.new(
      start_id: project_1.id,
      end_id: project_4.id,
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  it 'nullifies the `creator_id` column of projects whose creators do not exist' do
    # `delete` `user_3` so that the creator of `project_3` is removed, without invoking `dependent: :nullify` on `User`
    user_3.delete

    expect { subject }.to change { projects.where(creator_id: nil).count }.from(1).to(2)
  end
end
