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
end
