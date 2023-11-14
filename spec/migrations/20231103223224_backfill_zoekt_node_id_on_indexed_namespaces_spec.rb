# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillZoektNodeIdOnIndexedNamespaces, feature_category: :global_search do
  let!(:migration) { described_class.new }

  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }

  let(:zoekt_indexed_namespaces) { table(:zoekt_indexed_namespaces) }
  let(:zoekt_shards) { table(:zoekt_shards) }
  let(:zoekt_nodes) { table(:zoekt_nodes) }

  let(:indexed_namespace) do
    zoekt_indexed_namespaces.create!(
      zoekt_shard_id: shard.id,
      namespace_id: namespace.id
    )
  end

  let(:attributes) do
    {
      index_base_url: "https://index.example.com",
      search_base_url: "https://search.example.com",
      uuid: SecureRandom.uuid,
      used_bytes: 10,
      total_bytes: 100
    }.with_indifferent_access
  end

  let(:shard) do
    zoekt_shards.create!(attributes)
  end

  let(:node) do
    zoekt_nodes.create!(attributes)
  end

  describe '#up' do
    it 'backfills zoekt_node_id with zoekt_shard_id' do
      node
      expect(indexed_namespace.zoekt_node_id).to be_nil
      expect(indexed_namespace.zoekt_shard_id).to eq(shard.id)
      migrate!
      expect(indexed_namespace.reload.zoekt_node_id).to eq(node.id)
    end

    context 'when there is somehow more than one zoekt node' do
      let(:node) do
        zoekt_nodes.create!(
          index_base_url: "https://index.example.com",
          search_base_url: "https://search.example.com",
          uuid: SecureRandom.uuid,
          used_bytes: 10,
          total_bytes: 100,
          created_at: 5.days.ago
        )
      end

      let(:node_2) do
        zoekt_nodes.create!(
          index_base_url: "https://index2.example.com",
          search_base_url: "https://search2example.com",
          uuid: SecureRandom.uuid,
          used_bytes: 10,
          total_bytes: 100
        )
      end

      it 'uses the latest zoekt node' do
        expect(node_2.created_at).to be > node.created_at
        expect(indexed_namespace.zoekt_node_id).to be_nil
        migrate!
        expect(indexed_namespace.reload.zoekt_node_id).to eq(node_2.id)
      end
    end
  end
end
