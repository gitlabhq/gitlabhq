# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeGeoConcurrencyDefaultSettings, feature_category: :database, migration_version: 20250312124044 do
  let(:geo_nodes) { table(:geo_nodes) }

  describe '#up' do
    it 'does not change the values for existing geo nodes' do
      geo_node = geo_nodes.create!(name: "Test Node", url: "https://localhost:3000/gitlab")

      migrate!

      expect(geo_node.repos_max_capacity).to eq(25)
      expect(geo_node.verification_max_capacity).to eq(100)
      expect(geo_node.minimum_reverification_interval).to eq(7)
      expect(geo_node.container_repositories_max_capacity).to eq(10)
    end

    it 'ensures new geo nodes (if created after this migration) have the new default values' do
      migrate!

      geo_node = geo_nodes.create!(name: "Test Node", url: "https://localhost:3000/gitlab")

      expect(geo_node.repos_max_capacity).to eq(10)
      expect(geo_node.verification_max_capacity).to eq(10)
      expect(geo_node.minimum_reverification_interval).to eq(90)
      expect(geo_node.container_repositories_max_capacity).to eq(2)
    end
  end
end
