# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Migration, :click_house, feature_category: :database do
  describe '#create_dictionary' do
    let(:connection) { ClickHouse::Connection.new(:main) }
    let(:migration) { described_class.new(connection) }
    let(:sql) do
      <<~SQL
        CREATE DICTIONARY test_dict
        (
            `id` UInt64,
            `traversal_ids` Array(UInt64)
        )
        PRIMARY KEY id
        SOURCE(
          CLICKHOUSE(
            QUERY 'SELECT id, traversal_ids FROM siphon_namespaces'
          )
        )
        LIFETIME(MIN 60 MAX 300)
        LAYOUT(CACHE(SIZE_IN_CELLS 3000000))
      SQL
    end

    subject(:create_dictionary) { migration.create_dictionary(sql, source_tables: ['siphon_namespaces']) }

    it 'correctly creates a dictionary' do
      connection.execute("INSERT INTO siphon_namespaces (id, organization_id, traversal_ids) VALUES (3, 10, '[1,2,3]')")

      create_dictionary

      result = connection
        .select("SELECT arrayStringConcat(dictGet(test_dict, 'traversal_ids', 3), ',') AS traversal_ids")
        .first['traversal_ids']

      expect(result).to eq('1,2,3')
    end

    context 'when different source is given' do
      let(:sql) do
        <<~SQL
          CREATE DICTIONARY test_dict
          (
              `id` UInt64,
              `traversal_ids` Array(UInt64)
          )
          PRIMARY KEY id
          SOURCE(
            UNKNOWN_SOURCE(
              QUERY 'SELECT id, traversal_ids FROM siphon_namespaces'
            )
          )
          LIFETIME(MIN 60 MAX 300)
          LAYOUT(CACHE(SIZE_IN_CELLS 3000000))
        SQL
      end

      it 'raises error' do
        expect { create_dictionary }.to raise_error(/Unsupported dictionary source/)
      end
    end
  end
end
