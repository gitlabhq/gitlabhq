# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::DictionaryCredentialsHandler, feature_category: :database do
  describe '.replace_credentials_with_variables' do
    let(:database_name) { 'gitlab_clickhouse_development' }

    let(:statement) do
      <<~SQL
        CREATE DICTIONARY gitlab_clickhouse_development.namespace_traversal_paths_dict
        (
            `id` UInt64,
            `traversal_path` String
        )
        PRIMARY KEY id
        SOURCE(CLICKHOUSE(USER 'default' PASSWORD '[HIDDEN]' SECURE '0' QUERY 'SELECT id, traversal_path FROM
            (
                SELECT id, traversal_path
                FROM
                (
                    SELECT
                        id,
                        argMax(traversal_path, version) AS traversal_path,
                        argMax(deleted, version) AS deleted
                    FROM gitlab_clickhouse_development.namespace_traversal_paths
                    GROUP BY id
                )
                WHERE deleted = false
            )'))
        LIFETIME(MIN 300 MAX 500)
        LAYOUT(CACHE(SIZE_IN_CELLS 1000000))
      SQL
    end

    let(:expected_statement) do
      <<~SQL
        CREATE DICTIONARY gitlab_clickhouse_development.namespace_traversal_paths_dict
        (
            `id` UInt64,
            `traversal_path` String
        )
        PRIMARY KEY id
        SOURCE(CLICKHOUSE(USER '$DICTIONARY_USER' PASSWORD '$DICTIONARY_PASSWORD' SECURE '$DICTIONARY_SECURE' QUERY 'SELECT id, traversal_path FROM
            (
                SELECT id, traversal_path
                FROM
                (
                    SELECT
                        id,
                        argMax(traversal_path, version) AS traversal_path,
                        argMax(deleted, version) AS deleted
                    FROM $DICTIONARY_DATABASE.namespace_traversal_paths
                    GROUP BY id
                )
                WHERE deleted = false
            )'))
        LIFETIME(MIN 300 MAX 500)
        LAYOUT(CACHE(SIZE_IN_CELLS 1000000))
      SQL
    end

    subject(:redacted_statement) do
      described_class.replace_credentials_with_variables(database_name, statement)
    end

    it 'matches the expected output' do
      expect(redacted_statement).to eq(expected_statement)
    end

    it 'does not replace the database name in the CREATE DICTIONARY definition' do
      expect(redacted_statement).to include("CREATE DICTIONARY #{database_name}.namespace_traversal_paths_dict")
    end

    context 'when configuration options are missing' do
      let(:statement) do
        "SOURCE(CLICKHOUSE(QUERY 'SELECT 1 FROM #{database_name}.table'))"
      end

      it 'replaces the database but leaves missing options alone' do
        expect(redacted_statement).to include("$DICTIONARY_DATABASE.table")
        expect(redacted_statement).not_to include("$DICTIONARY_USER")
      end
    end
  end

  describe '.replace_variables_with_credentials' do
    let(:statement) do
      <<~SQL
        CREATE DICTIONARY namespace_traversal_paths_dict
        (
            `id` UInt64,
            `traversal_path` String
        )
        PRIMARY KEY id
        SOURCE(CLICKHOUSE(USER '$DICTIONARY_USER' PASSWORD '$DICTIONARY_PASSWORD' SECURE '$DICTIONARY_SECURE' QUERY 'SELECT id, traversal_path FROM
            (
                SELECT id, traversal_path
                FROM
                (
                    SELECT
                        id,
                        argMax(traversal_path, version) AS traversal_path,
                        argMax(deleted, version) AS deleted
                    FROM $DICTIONARY_DATABASE.namespace_traversal_paths
                    GROUP BY id
                )
                WHERE deleted = false
            )'))
        LIFETIME(MIN 300 MAX 500)
        LAYOUT(CACHE(SIZE_IN_CELLS 1000000))
      SQL
    end

    let(:expected_statement) do
      <<~SQL
        CREATE DICTIONARY namespace_traversal_paths_dict
        (
            `id` UInt64,
            `traversal_path` String
        )
        PRIMARY KEY id
        SOURCE(CLICKHOUSE(USER 'user' PASSWORD 'pass' SECURE '0' QUERY 'SELECT id, traversal_path FROM
            (
                SELECT id, traversal_path
                FROM
                (
                    SELECT
                        id,
                        argMax(traversal_path, version) AS traversal_path,
                        argMax(deleted, version) AS deleted
                    FROM foo_db.namespace_traversal_paths
                    GROUP BY id
                )
                WHERE deleted = false
            )'))
        LIFETIME(MIN 300 MAX 500)
        LAYOUT(CACHE(SIZE_IN_CELLS 1000000))
      SQL
    end

    let(:ch_config) { ClickHouse::Client::Configuration.new }
    let(:url) { 'http://localhost:1111' }

    subject(:transformed_statement) do
      described_class.replace_variables_with_credentials(ch_config.databases[:my_db], statement)
    end

    before do
      ch_config.register_database(
        :my_db,
        database: 'foo_db',
        url: url,
        username: 'user',
        password: 'pass'
      )
    end

    it 'correctly transforms the templated statement' do
      expect(transformed_statement).to eq(expected_statement)
    end

    context 'when secure url is used' do
      let(:url) { 'https://localhost:1111' }

      it "uses `SECURE '1' flag" do
        expect(transformed_statement).to include("SECURE '1'")
      end
    end
  end
end
