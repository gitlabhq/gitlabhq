# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteInvalidProtectedTagCreateAccessLevels,
  feature_category: :source_code_management do
  let(:organizations_table) { table(:organizations) }
  let(:projects_table) { table(:projects) }
  let(:protected_tags_table) { table(:protected_tags) }
  let(:namespaces_table) { table(:namespaces) }
  let(:protected_tag_create_access_levels_table) { table(:protected_tag_create_access_levels) }
  let(:project_group_links_table) { table(:project_group_links) }
  let(:users_table) { table(:users) }

  let(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 5) }

  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }

  let(:project_group) do
    namespaces_table.create!(name: 'group-1', path: 'group-1', type: 'Group', organization_id: organization.id)
  end

  let(:project_namespace) do
    namespaces_table.create!(name: 'namespace', path: 'namespace-2', type: 'Project', organization_id: organization.id)
  end

  let!(:project_1) do
    projects_table
      .create!(
        name: 'project1',
        path: 'path1',
        organization_id: organization.id,
        namespace_id: project_group.id,
        project_namespace_id: project_namespace.id,
        visibility_level: 0
      )
  end

  subject(:perform_migration) do
    described_class.new(start_id: protected_tag_create_access_levels_table.minimum(:id),
      end_id: protected_tag_create_access_levels_table.maximum(:id),
      batch_table: :protected_tag_create_access_levels,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection)
                   .perform
  end

  context 'when there are push access levels' do
    let(:protected_tag) { protected_tags_table.create!(project_id: project_1.id, name: 'name') }
    let!(:push_access_level_for_user) do
      protected_tag_create_access_levels_table.create!(
        protected_tag_id: protected_tag.id,
        user_id: user1.id
      )
    end

    let(:invited_group) { namespaces_table.create!(name: 'group-2', path: 'group-2', type: 'Group') }
    let!(:invited_group_link) do
      project_group_links_table.create!(project_id: project_1.id, group_id: invited_group.id)
    end

    let!(:push_access_level_with_linked_group) do
      protected_tag_create_access_levels_table.create!(
        protected_tag_id: protected_tag.id,
        group_id: invited_group.id
      )
    end

    let!(:push_access_level_with_unlinked_group) do
      protected_tag_create_access_levels_table.create!(
        protected_tag_id: protected_tag.id,
        group_id: project_group.id
      )
    end

    it 'deletes push access levels with groups that do not have project_group_links to the project' do
      expect { subject }.to change { protected_tag_create_access_levels_table.count }.from(3).to(2)
      expect(protected_tag_create_access_levels_table.all).to contain_exactly(
        push_access_level_with_linked_group,
        push_access_level_for_user
      )
    end
  end
end
