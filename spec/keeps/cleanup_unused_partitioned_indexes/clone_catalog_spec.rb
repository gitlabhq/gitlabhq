# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_partitioned_indexes'

RSpec.describe Keeps::CleanupUnusedPartitionedIndexes::CloneCatalog, feature_category: :database do
  let(:pg_client) { instance_double(PG::Connection) }

  subject(:catalog) { described_class.new }

  before do
    stub_env('POSTGRES_AI_CONNECTION_STRING', 'host=clone dbname=gitlabhq_dblab')
    stub_env('POSTGRES_AI_PASSWORD', 'secret')
    allow(PG).to receive(:connect).and_return(pg_client)
  end

  describe '.available?' do
    it 'is true when both env vars are present' do
      expect(described_class).to be_available
    end

    it 'is false when the connection string is missing' do
      stub_env('POSTGRES_AI_CONNECTION_STRING', '')

      expect(described_class).not_to be_available
    end
  end

  describe '#initialize' do
    it 'raises without credentials' do
      stub_env('POSTGRES_AI_PASSWORD', '')

      expect { described_class.new }.to raise_error(described_class::Error, /credentials/)
    end
  end

  describe '#candidate_parent_indexes' do
    it 'maps rows to ParentIndex structs and filters temporary reindex names', :aggregate_failures do
      rows = [
        { 'schema' => 'public', 'name' => 'p_ci_builds_user_id_idx', 'tablename' => 'p_ci_builds',
          'definition' => 'CREATE INDEX ...' }
      ]
      allow(pg_client).to receive(:exec_params) do |query, params|
        expect(query).to include("EXISTS")
        expect(query).to include('postgres_partitioned_tables')
        expect(query).to include("i.type = 'btree'")
        # Write-locked tables belong to another decomposed database and have
        # a stale partition set there; they must never become candidates. The
        # left(..., 63) matches PostgreSQL's identifier truncation, without
        # which tables named over 31 chars would leak through.
        expect(query).to include("t.tgname = left('gitlab_schema_write_trigger_for_' || i.tablename, 63)")
        expect(params.first).to include(Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN)
        rows
      end

      result = catalog.candidate_parent_indexes

      expect(result.size).to eq(1)
      expect(result.first).to have_attributes(
        schema: 'public', name: 'p_ci_builds_user_id_idx', tablename: 'p_ci_builds'
      )
    end
  end

  describe '#child_index_names' do
    it 'reads real child names via pg_inherits' do
      pg_result = instance_double(PG::Result)
      allow(pg_result).to receive(:field_values).with('child_index')
        .and_return(%w[ci_builds_101_user_id_idx ci_builds_102_user_id_idx])
      allow(pg_client).to receive(:exec_params) do |query, params|
        expect(query).to include('pg_inherits')
        expect(params).to eq(['p_ci_builds_user_id_idx'])
        pg_result
      end

      expect(catalog.child_index_names('p_ci_builds_user_id_idx'))
        .to eq(%w[ci_builds_101_user_id_idx ci_builds_102_user_id_idx])
    end
  end

  describe '#candidate_parent_indexes against the real test database catalog' do
    before do
      allow(PG).to receive(:connect).and_call_original

      config = ApplicationRecord.connection_db_config.configuration_hash
      connection_string = ["dbname=#{config[:database]}"]
      connection_string << "host=#{config[:host]}" if config[:host]
      connection_string << "port=#{config[:port]}" if config[:port]
      connection_string << "user=#{config[:username]}" if config[:username]

      stub_env('POSTGRES_AI_CONNECTION_STRING', connection_string.join(' '))
      # Trust-authenticated local databases have no password; PG ignores an
      # unused one, and available? requires it to be present.
      stub_env('POSTGRES_AI_PASSWORD', config[:password].presence || 'unused')
    end

    after do
      catalog.close
    end

    it 'returns only plain btree parents on partitioned tables', :aggregate_failures do
      result = catalog.candidate_parent_indexes

      expect(result).not_to be_empty
      expect(result.map(&:definition)).to all(include('USING btree'))
      expect(result.map(&:definition)).to all(satisfy('have no partial predicate') { |d| d.exclude?(' WHERE ') })
      # A known GIN parent index must be excluded by the btree filter.
      expect(result.map(&:name)).not_to include('index_issue_search_data_on_search_vector')
    end
  end

  describe '#close' do
    it 'closes the connection once established' do
      allow(pg_client).to receive(:exec_params).and_return(instance_double(PG::Result, field_values: []))
      allow(pg_client).to receive(:close)

      catalog.child_index_names('p_ci_builds_user_id_idx')
      catalog.close

      expect(pg_client).to have_received(:close)
    end

    it 'is a no-op when no connection was established' do
      expect(PG).not_to receive(:connect)

      catalog.close
    end
  end

  describe '#index_columns' do
    it 'returns ordered column symbols' do
      pg_result = instance_double(PG::Result)
      allow(pg_result).to receive(:field_values).with('attname').and_return(%w[user_id name])
      allow(pg_client).to receive(:exec_params).and_return(pg_result)

      expect(catalog.index_columns('p_ci_builds_user_id_idx')).to eq(%i[user_id name])
    end
  end
end
