# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Connection, click_house: :without_migrations, feature_category: :database do
  let(:connection) { described_class.new(:main) }

  describe '#database_name' do
    it 'returns the configured database name' do
      name = ClickHouse::Client.configuration.databases[:main].database
      expect(connection.database_name).to eq(name)
    end
  end

  describe '#select' do
    it 'proxies select to client' do
      expect(
        connection.select('SELECT 1')
      ).to eq([{ '1' => 1 }])
    end
  end

  describe '#execute' do
    it 'proxies execute to client' do
      create_test_table

      connection.execute(
        <<~SQL
          INSERT INTO test_table VALUES (1), (2), (3)
        SQL
      )

      expect(connection.select('SELECT id FROM test_table')).to eq(
        [{ 'id' => 1 }, { 'id' => 2 }, { 'id' => 3 }]
      )
    end
  end

  describe '#table_exists?' do
    it "return false when table doesn't exist" do
      expect(connection.table_exists?('test_table')).to eq(false)
    end

    it 'returns true when table exists' do
      create_test_table

      expect(connection.table_exists?('test_table')).to eq(true)
    end
  end

  def create_test_table
    connection.execute(
      <<~SQL
        CREATE TABLE test_table (
          id   UInt64
        ) ENGINE = MergeTree
        PRIMARY KEY(id)
      SQL
    )
  end
end
