# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::DbLoopStatsActivity, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:output) { Gitlab::Database::Sos::Output.new(temp_directory, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }

  after do
    FileUtils.remove_entry(temp_directory)
  end

  describe '#run' do
    it 'successfully writes each query result to csv' do
      expect_next_instance_of(Gitlab::Database::Sos::Output) do |instance|
        expect(instance).to receive(:write_file).exactly(described_class::QUERIES.count).times
      end
      handler.run
    end
  end

  describe 'individual queries' do
    described_class::QUERIES.each do |name, query|
      it "successfully executes and returns results for #{name}" do
        result = handler.execute_query(query)

        expect(result).to be_a(PG::Result)
        expect(result.nfields).to be > 0

        case name
        when :pg_stat_user_tables
          expect(result.fields).to include("timestamp", "relid", "schemaname", "relname", "seq_scan")
        when :pg_stat_user_indexes
          expect(result.fields).to include("timestamp", "relid", "indexrelid", "schemaname", "relname")
        when :pg_statio_user_tables
          expect(result.fields).to include("timestamp", "relid", "schemaname", "relname", "heap_blks_read")
        when :pg_statio_user_indexes
          expect(result.fields).to include("timestamp", "relid", "indexrelid", "schemaname", "relname", "idx_blks_read")
        when :table_relation_size
          expect(result.fields).to eq %w[timestamp relation total_size_bytes]
        when :pg_lock_stat_activity
          expect(result.fields).to include("timestamp", "pid", "usename", "application_name", "client_addr")
        end
      end
    end
  end
end
