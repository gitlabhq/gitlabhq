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

    it 'adds columns where missing' do
      # First create a table structure with all columns
      geo_nodes.create!(name: "Test Node", url: "https://localhost:3000/gitlab")

      # Drop some columns to simulate the scenario where columns are missing
      connection = ActiveRecord::Base.connection
      columns_to_drop = [:verification_max_capacity, :minimum_reverification_interval]

      columns_to_drop.each do |column|
        connection.remove_column :geo_nodes, column
      end

      # Verify columns are actually gone
      expect(connection.column_exists?(:geo_nodes, :verification_max_capacity)).to be_falsey
      expect(connection.column_exists?(:geo_nodes, :minimum_reverification_interval)).to be_falsey

      # Run the migration
      migrate!

      # Reload schema to see the new columns
      connection.schema_cache.clear!
      geo_nodes.reset_column_information

      # Verify columns were added with correct default values
      expect(connection.column_exists?(:geo_nodes, :verification_max_capacity)).to be_truthy
      expect(connection.column_exists?(:geo_nodes, :minimum_reverification_interval)).to be_truthy

      # Create a new node to verify default values
      new_node = geo_nodes.create!(name: "New Node", url: "https://localhost:3001/gitlab")
      expect(new_node.verification_max_capacity).to eq(10)
      expect(new_node.minimum_reverification_interval).to eq(90)
    end
  end
end
