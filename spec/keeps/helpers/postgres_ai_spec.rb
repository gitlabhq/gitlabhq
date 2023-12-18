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
      SELECT id, created_at, updated_at, finished_at, started_at, status, job_class_name
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
end
