# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveReplicasWithEvictedIndices, migration: :gitlab_main, feature_category: :global_search do
  let(:zoekt_nodes) { table(:zoekt_nodes) }
  let(:zoekt_node) { zoekt_nodes.create!(uuid: SecureRandom.uuid, index_base_url: 'i_url', search_base_url: 's_url') }
  let(:organizations) { table(:organizations) }
  let(:organization) { organizations.create!(path: 'path') }
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'name', path: 'path', type: 'Group', organization_id: organization.id) }
  let(:zoekt_indices) { table(:zoekt_indices) }
  let!(:evicted_index_without_zoekt_replica) do
    zoekt_indices.create!(
      state: described_class::EVICTED_STATE,
      zoekt_node_id: zoekt_node.id,
      namespace_id: namespace.id
    )
  end

  let(:zoekt_replicas) { table(:zoekt_replicas) }
  let(:zoekt_enabled_namespaces) { table(:zoekt_enabled_namespaces) }
  let(:zoekt_enabled_namespace) { zoekt_enabled_namespaces.create!(root_namespace_id: namespace.id) }
  let(:zoekt_replica) do
    zoekt_replicas.create!(zoekt_enabled_namespace_id: zoekt_enabled_namespace.id, namespace_id: namespace.id)
  end

  let!(:evicted_index_with_zoekt_replica) do
    zoekt_indices.create!(
      state: described_class::EVICTED_STATE,
      zoekt_node_id: zoekt_node.id,
      namespace_id: namespace.id,
      zoekt_replica_id: zoekt_replica.id
    )
  end

  let(:zoekt_replica2) do
    zoekt_replicas.create!(zoekt_enabled_namespace_id: zoekt_enabled_namespace.id, namespace_id: namespace.id)
  end

  let!(:pending_eviction_index_with_zoekt_replica) do
    zoekt_indices.create!(
      state: 220,
      zoekt_node_id: zoekt_node.id,
      namespace_id: namespace.id,
      zoekt_replica_id: zoekt_replica2.id
    )
  end

  describe '#up' do
    it 'deletes the zoekt_replicas of the evicted indices' do
      expect(zoekt_replicas.exists?(id: evicted_index_with_zoekt_replica.zoekt_replica_id)).to be true
      migrate!
      expect(zoekt_replicas.exists?(id: evicted_index_with_zoekt_replica.zoekt_replica_id)).to be false
      expect(pending_eviction_index_with_zoekt_replica.reload.zoekt_replica_id).not_to be_nil
    end
  end
end
