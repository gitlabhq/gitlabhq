# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupRegistryUpstreamsWithNullUpstreamId, feature_category: :virtual_registry do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:registry_upstreams) { table(:virtual_registries_packages_maven_registry_upstreams) }
  let(:registries) { table(:virtual_registries_packages_maven_registries) }
  let(:upstreams) { table(:virtual_registries_packages_maven_upstreams) }
  let(:local_upstreams) { table(:virtual_registries_packages_maven_local_upstreams) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:group) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:project) do
    projects.create!(
      namespace_id: group.id,
      project_namespace_id: group.id,
      organization_id: organization.id
    )
  end

  let!(:registry) do
    registries.create!(group_id: group.id, name: 'test-registry')
  end

  let!(:upstream) do
    upstreams.create!(
      group_id: group.id,
      url: 'https://example.com/maven',
      name: 'test-upstream'
    )
  end

  let!(:local_upstream) do
    local_upstreams.create!(
      group_id: group.id,
      local_project_id: project.id,
      name: 'test-local-upstream'
    )
  end

  # This record has local_upstream_id set (no upstream_id) - should be deleted on rollback
  let!(:registry_upstream_with_local_upstream) do
    registry_upstreams.create!(
      group_id: group.id,
      registry_id: registry.id,
      upstream_id: nil,
      local_upstream_id: local_upstream.id,
      position: 1
    )
  end

  # This record has upstream_id set - should be preserved on rollback
  let!(:registry_upstream_with_upstream_id) do
    registry_upstreams.create!(
      group_id: group.id,
      registry_id: registry.id,
      upstream_id: upstream.id,
      local_upstream_id: nil,
      position: 2
    )
  end

  describe '#up' do
    it 'is a no-op' do
      expect { migrate! }.not_to change { registry_upstreams.count }
    end
  end

  describe '#down' do
    it 'removes records with NULL upstream_id and preserves others without changing position' do
      migrate!
      schema_migrate_down!

      expect(registry_upstreams.where(upstream_id: nil)).to be_empty
      expect(registry_upstreams.count).to eq(1)

      remaining_record = registry_upstreams.find_by(id: registry_upstream_with_upstream_id.id)
      expect(remaining_record).to be_present
      expect(remaining_record.position).to eq(2)
    end
  end
end
