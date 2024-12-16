# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetOrganizationIdForBulkImportEntities, migration: :gitlab_main, feature_category: :importers do
  let(:migration) { described_class.new }

  let(:bulk_import_entities) { table(:bulk_import_entities) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:bulk_imports) { table(:bulk_imports) }

  let!(:default_organization) { organizations.create!(id: 1, path: '/') }
  let!(:user) { users.create!(email: 'user1@example.com', username: 'user1', projects_limit: 100) }
  let!(:project_namespace) { namespaces.create!(name: 'project1', path: 'project1', type: 'Project') }
  let!(:bulk_import) { bulk_imports.create!(user_id: user.id, source_type: 1, status: 0) }

  let(:default_entity_attrs) do
    {
      source_type: 1, source_full_path: '', bulk_import_id: bulk_import.id, destination_namespace: 'dest',
      destination_name: 'dest', created_at: Time.now, updated_at: Time.now, status: 0
    }
  end

  let!(:custom_organization) { organizations.create!(id: 2, path: '/custom') }

  let(:group) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }

  let(:project) do
    projects.create!(
      name: 'foo', path: 'foo', namespace_id: group.id, project_namespace_id: project_namespace.id
    )
  end

  let!(:entity_without_any) { bulk_import_entities.create!(**default_entity_attrs) }
  let!(:entity_with_project) { bulk_import_entities.create!(**default_entity_attrs, project_id: project.id) }
  let!(:entity_with_namespace) { bulk_import_entities.create!(**default_entity_attrs, namespace_id: group.id) }
  let!(:entity_with_organization) do
    bulk_import_entities.create!(**default_entity_attrs, organization_id: custom_organization.id)
  end

  describe '#up' do
    it 'updates all bulk_import_entities that do not have any sharding key' do
      expect { migrate! }.to change { entity_without_any.reload.organization_id }.from(nil).to(1)
        .and not_change { entity_with_project.reload.organization_id }
        .and not_change { entity_with_namespace.reload.organization_id }
        .and not_change { entity_with_organization.reload.organization_id }
    end
  end
end
