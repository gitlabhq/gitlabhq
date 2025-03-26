# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/postgres_ai'

RSpec.describe Keeps::Helpers::PostgresAi, feature_category: :tooling do
  let(:connection_string) { 'host=localhost port=1234 user=user dbname=dbname' }
  let(:password) { 'password' }
  let(:pg_client) { instance_double(PG::Connection) }

  before do
    stub_env('POSTGRES_AI_CONNECTION_STRING', connection_string)
    stub_env('POSTGRES_AI_PASSWORD', password)

    allow(PG).to receive(:connect).with(connection_string, password: password).and_return(pg_client)
  end

  describe '#initialize' do
    shared_examples 'no credentials supplied' do
      it do
        expect { described_class.new }.to raise_error(described_class::Error, "No credentials supplied")
      end
    end

    context 'with no connection string' do
      let(:connection_string) { '' }

      include_examples 'no credentials supplied'
    end

    context 'with no password' do
      let(:password) { '' }

      include_examples 'no credentials supplied'
    end
  end

  describe '#fetch_background_migration_status' do
    let(:job_class_name) { 'ExampleJob' }
    let(:query) do
      <<~SQL
      SELECT id, created_at, updated_at, finished_at, started_at, status, job_class_name,
      gitlab_schema, total_tuple_count
      FROM batched_background_migrations
      WHERE job_class_name = $1::text
      SQL
    end

    let(:query_response) { double }

    subject(:result) { described_class.new.fetch_background_migration_status(job_class_name) }

    it 'fetches background migration data from Postgres AI' do
      expect(pg_client).to receive(:exec_params).with(query, [job_class_name]).and_return(query_response)
      expect(result).to eq(query_response)
    end
  end

  describe '#fetch_migrated_tuple_count' do
    let(:batched_background_migration_id) { 100 }
    let(:query) do
      <<~SQL
      SELECT SUM("batched_background_migration_jobs"."batch_size")
      FROM "batched_background_migration_jobs"
      WHERE "batched_background_migration_jobs"."batched_background_migration_id" = 100
      AND ("batched_background_migration_jobs"."status" IN (3))
      SQL
    end

    let(:query_response) { double }

    subject(:result) { described_class.new.fetch_migrated_tuple_count(batched_background_migration_id) }

    it 'fetches data from Postgres AI' do
      expect(pg_client).to receive(:exec_params).with(query).and_return(query_response)
      expect(result).to eq(query_response)
    end
  end

  describe '#fetch_postgres_table_size' do
    let(:table_name) { '_test_table' }
    let(:query) do
      <<~SQL
        SELECT
          identifier,
          schema_name,
          table_name,
          total_size,
          table_size,
          index_size,
          size_in_bytes,
          CASE
            WHEN size_in_bytes < 10 * 1024^3 THEN 'small'
            WHEN size_in_bytes < 50 * 1024^3 THEN 'medium'
            WHEN size_in_bytes < 100 * 1024^3 THEN 'large'
            ELSE 'over_limit'
          END AS classification
        FROM postgres_table_sizes
        WHERE table_name = $1::text
      SQL
    end

    let(:query_response) { double }

    subject(:result) { described_class.new.fetch_postgres_table_size(table_name) }

    it 'fetches table size data from Postgres AI' do
      expect(pg_client).to receive(:exec_params).with(query, [table_name]).and_return(query_response)
      expect(result).to eq(query_response)
    end
  end

  describe '#table_has_data?' do
    let(:table_name) { "test_table" }
    let(:table_name_quoted) { "\"table_name\"" }
    let(:query) { "SELECT EXISTS (SELECT 1 FROM #{table_name_quoted} LIMIT 1)" }

    let(:query_response) { double }

    subject(:result) { described_class.new.table_has_data?(table_name) }

    it 'fetches if the table contains any data from Postgres AI' do
      expect(pg_client).to receive(:exec_params).with(query).and_return(query_response)
      expect(pg_client).to receive(:quote_ident).with(table_name).and_return(table_name_quoted)
      expect(result).to eq(query_response)
    end
  end
end
