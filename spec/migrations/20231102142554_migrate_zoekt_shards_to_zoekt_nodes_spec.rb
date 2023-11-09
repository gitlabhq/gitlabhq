# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateZoektShardsToZoektNodes, feature_category: :global_search do
  let!(:migration) { described_class.new }

  let(:attributes) do
    {
      index_base_url: "https://index.example.com",
      search_base_url: "https://search.example.com",
      uuid: SecureRandom.uuid,
      used_bytes: 10,
      total_bytes: 100
    }.with_indifferent_access
  end

  let(:zoekt_shards) { table(:zoekt_shards) }
  let(:zoekt_nodes) { table(:zoekt_nodes) }

  let(:shard) do
    zoekt_shards.create!(attributes)
  end

  let(:node) do
    zoekt_nodes.create!(attributes)
  end

  describe '#up' do
    it 'migrates zoekt_shard records to zoekt_nodes' do
      shard
      expect { migrate! }.to change { zoekt_nodes.count }.from(0).to(1)
      expect(zoekt_nodes.first.attributes.with_indifferent_access).to include(attributes)
    end
  end

  describe '#down' do
    it 'deletes all zoekt_node records' do
      node
      expect { migration.down }.to change { zoekt_nodes.count }.from(1).to(0)
    end
  end
end
