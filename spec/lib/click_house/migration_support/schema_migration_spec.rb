# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::SchemaMigration, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection) }
  let(:table_name) { 'schema_migrations' }
  let(:schema_migration) { described_class.new(connection, table_name: table_name) }

  describe '#ensure_table' do
    context 'when table does not exist' do
      before do
        allow(connection).to receive(:table_exists?).with(table_name).and_return(false)
        allow(connection).to receive(:execute)
      end

      context 'when connection uses replicated engine' do
        before do
          allow(connection).to receive(:replicated_engine?).and_return(true)
        end

        it 'creates table with ReplicatedReplacingMergeTree engine' do
          schema_migration.ensure_table

          expect(connection).to have_received(:execute) do |query|
            expect(query).to include('ReplicatedReplacingMergeTree')
            expect(query).not_to match(/ENGINE\s*=\s*ReplacingMergeTree/)
          end
        end
      end

      context 'when connection does not use replicated engine' do
        before do
          allow(connection).to receive(:replicated_engine?).and_return(false)
        end

        it 'creates table with ReplacingMergeTree engine' do
          schema_migration.ensure_table

          expect(connection).to have_received(:execute) do |query|
            expect(query).to include('ReplacingMergeTree')
            expect(query).not_to include('ReplicatedReplacingMergeTree')
          end
        end
      end
    end
  end
end
