# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::PgStatStatements, feature_category: :database do
  include Database::DatabaseHelpers

  let(:temp_directory) { Dir.mktmpdir }
  let(:output) { Gitlab::Database::Sos::Output.new(temp_directory, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }

  after do
    FileUtils.remove_entry(temp_directory)
  end

  describe '#run' do
    context 'when pg_stat_statements is installed' do
      before do
        connection.execute(<<~SQL)
          CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
          CREATE TABLE _test_pg_stat_statements_copy (LIKE pg_stat_statements);
          CREATE OR REPLACE VIEW pg_stat_statements AS ( SELECT * FROM _test_pg_stat_statements_copy );
        SQL

        connection.execute(<<~SQL.squish)
            INSERT INTO pg_stat_statements (
              userid, dbid, queryid, query,
              plans, total_plan_time, min_plan_time, max_plan_time, mean_plan_time)
            VALUES (
              1, 2727493, 23234938938, 'ALTER TABLE "table" DISABLE TRIGGER ALL', 0,
              0.0, 0.0, 0.0, 0.0)
        SQL
      end

      it "successfully writes the executed query results to CSV" do
        allow(handler).to receive(:pg_stat_statements_installed?).and_return(true)
        handler.run
        file_path = File.join(temp_directory, db_name, "pg_stat_statements", "*.csv")
        expect(Dir.glob(file_path).any?).to be true
      end
    end

    context 'when pg_stat_statements is not installed' do
      it "skips executing and writing to csv" do
        allow(handler).to receive(:pg_stat_statements_installed?).and_return(false)

        handler.run

        file_path = File.join(temp_directory, db_name, "pg_stat_statements", "*.csv")
        expect(Dir.glob(file_path).any?).to be false
      end
    end
  end

  describe '#pg_stats_statements_installed?' do
    context 'when the pg_stat_statements is installed' do
      before do
        connection.execute('CREATE EXTENSION IF NOT EXISTS pg_stat_statements;')
      end

      it 'returns true' do
        expect(handler.pg_stat_statements_installed?).to be true
      end
    end

    context 'when pg_stat_statments is not installed' do
      before do
        connection.execute('DROP EXTENSION IF EXISTS pg_stat_statements;')
      end

      it 'returns false' do
        expect(handler.pg_stat_statements_installed?).to be false
      end
    end
  end
end
