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
      gitlab_schema, total_tuple_count, table_name, column_name, job_arguments
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
    include Database::DatabaseHelpers

    let(:connection) { ApplicationRecord.connection }

    # ActiveRecord's raw connection has a type map installed, so `is_partition` arrives as a Ruby
    # boolean; a plain PG.connect, as used in production, returns 't' and 'f'. Normalise through
    # Gitlab::Utils.to_boolean, which is what the keep applies to the value, so the assertions
    # are about the column's meaning rather than the driver's type mapping.
    subject(:result) do
      described_class.new.fetch_postgres_table_size(table_name).to_a.map do |row|
        row.merge('is_partition' => Gitlab::Utils.to_boolean(row.fetch('is_partition')))
      end
    end

    # Run the query against the test database so the partition resolution is exercised for real.
    # The view is swapped for a table so realistic production sizes can be recorded for the
    # relations involved.
    before do
      allow(PG).to receive(:connect).with(connection_string, password: password).and_return(connection.raw_connection)

      swapout_view_for_table(:postgres_table_sizes, connection: connection)
    end

    def record_size(schema_name, relation_name, size_in_bytes)
      create(
        :postgres_table_size,
        identifier: "#{schema_name}.#{relation_name}",
        schema_name: schema_name,
        table_name: relation_name,
        size_in_bytes: size_in_bytes
      )
    end

    context 'with an unpartitioned table' do
      let(:table_name) { '_test_table' }

      before do
        record_size('public', '_test_table', 20.gigabytes)
        # A same-named relation outside the public schema (a clone leftover, for example) must
        # not decide the classification.
        record_size('gitlab_partitions_static', '_test_table', 200.gigabytes)
      end

      it 'classifies the table from its own row in the public schema' do
        expect(result).to contain_exactly(
          a_hash_including(
            'identifier' => 'public._test_table',
            'is_partition' => false,
            'classification' => 'medium'
          )
        )
      end
    end

    context 'with a hash-partitioned table' do
      let(:table_name) { '_test_partitioned_table' }

      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_partitioned_table (
            id bigint NOT NULL,
            project_id bigint NOT NULL,
            PRIMARY KEY (id, project_id)
          ) PARTITION BY HASH (project_id);

          CREATE TABLE gitlab_partitions_static._test_partitioned_table_00
            PARTITION OF _test_partitioned_table FOR VALUES WITH (MODULUS 2, REMAINDER 0);

          CREATE TABLE gitlab_partitions_static._test_partitioned_table_01
            PARTITION OF _test_partitioned_table FOR VALUES WITH (MODULUS 2, REMAINDER 1);
        SQL

        record_size('gitlab_partitions_static', '_test_partitioned_table_00', 5.gigabytes)
        record_size('gitlab_partitions_static', '_test_partitioned_table_01', 42.gigabytes)
        # Shares the table's name prefix but is not one of its partitions, so it must be ignored.
        record_size('public', '_test_partitioned_table_archive', 200.gigabytes)
      end

      context 'when the empty parent has a row in the view' do
        before do
          record_size('public', '_test_partitioned_table', 0)
        end

        it 'classifies the table by its largest partition rather than the empty parent' do
          expect(result).to contain_exactly(
            a_hash_including(
              'identifier' => 'gitlab_partitions_static._test_partitioned_table_01',
              'is_partition' => true,
              'classification' => 'medium'
            )
          )
        end
      end

      context 'when the parent has no row in the view' do
        it 'still classifies the table by its largest partition' do
          expect(result).to contain_exactly(
            a_hash_including(
              'identifier' => 'gitlab_partitions_static._test_partitioned_table_01',
              'is_partition' => true,
              'classification' => 'medium'
            )
          )
        end
      end
    end

    context 'with a table that has no row in the view' do
      let(:table_name) { '_test_missing_table' }

      it 'returns no rows' do
        expect(result).to be_empty
      end
    end
  end

  describe '#table_write_locked?' do
    let(:table_name) { "test_table" }
    let(:query) do
      <<~SQL
        SELECT EXISTS (
          SELECT 1
          FROM pg_trigger
          INNER JOIN pg_class ON pg_class.oid = pg_trigger.tgrelid
          INNER JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
          INNER JOIN pg_proc ON pg_proc.oid = pg_trigger.tgfoid
          WHERE pg_class.relname = $1::text
            AND pg_namespace.nspname = 'public'
            AND pg_proc.proname = 'gitlab_schema_prevent_write'
        )
      SQL
    end

    subject(:result) { described_class.new.table_write_locked?(table_name) }

    context 'when the table has a lock-writes trigger' do
      it 'returns true' do
        expect(pg_client).to receive(:exec_params)
          .with(query, [table_name])
          .and_return([{ 'exists' => 't' }])

        expect(result).to be(true)
      end
    end

    context 'when the table has no lock-writes trigger' do
      it 'returns false' do
        expect(pg_client).to receive(:exec_params)
          .with(query, [table_name])
          .and_return([{ 'exists' => 'f' }])

        expect(result).to be(false)
      end
    end
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

  describe '#close' do
    it 'closes the connection once established' do
      allow(pg_client).to receive(:close)
      helper = described_class.new

      helper.pg_client
      helper.close

      expect(pg_client).to have_received(:close)
    end

    it 'is a no-op when no connection was established' do
      expect(PG).not_to receive(:connect)

      described_class.new.close
    end
  end
end
