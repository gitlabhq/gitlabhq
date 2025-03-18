# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::BaseDbStatsHandler, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:output_file_path) { temp_directory }
  let(:output) { Gitlab::Database::Sos::Output.new(output_file_path, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }
  let(:queries) do
    {
      pg_show_all_settings: 'SHOW ALL;',
      pg_statio_user_tables: 'SELECT now() AS timestamp, * FROM pg_statio_user_tables;'
    }
  end

  let(:result) { ApplicationRecord.connection.execute(queries[:pg_show_all_settings]) }
  let(:result_with_timestamp) { ApplicationRecord.connection.execute(queries[:pg_statio_user_tables]) }
  let(:timestamp) { Time.zone.now.strftime("%Y%m%d_%H%M%S") }
  let(:file_path_with_timestamp) do
    File.join(output_file_path, db_name, queries.keys.last.to_s, "#{timestamp}.csv")
  end

  let(:file_path_without_timestamp) { File.join(output_file_path, db_name, "#{queries.each_key.first}.csv") }

  after do
    FileUtils.remove_entry(temp_directory)
  end

  describe '#initialize' do
    it 'sets the attributes' do
      expect(handler.connection).to eq(connection)
      expect(handler.name).to eq(db_name)
      expect(handler.output).to eq(output)
    end
  end

  describe '#execute_query' do
    context "when a query is sucessfully executed" do
      it 'executes the query and returns the result' do
        result = handler.execute_query(queries[:pg_show_all_settings])
        expect(result).to be_an(PG::Result)
        expect(result.ntuples).to be > 0
      end
    end

    context "when an error occurs" do
      let(:invalid_query) { 'SELECT * FROM some_table' }

      it 'logs the error and returns an empty array' do
        expect(Gitlab::AppLogger).to receive(:error) do |message|
          expect(message).to include("Error executing on DB:#{db_name} query:#{invalid_query} error message")
        end

        result = handler.execute_query(invalid_query)
        expect(result).to eq([])
      end
    end
  end

  describe '#write_to_csv' do
    before do
      allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2023-01-01 12:00:00 UTC'))

      allow(Gitlab::Database::Sos::DbStatsActivity).to receive(:queries).and_return({
        pg_show_all_settings: 'SHOW ALL;'
      })

      allow(Gitlab::Database::Sos::DbLoopStatsActivity).to receive(:queries).and_return({
        pg_statio_user_tables: 'SELECT now() AS timestamp, * FROM pg_statio_user_tables;'
      })
    end

    context 'when result exists' do
      it 'creates a CSV file with the correct headers and data (if applicable) without timestamps' do
        handler.write_to_csv(queries.each_key.first, result)
        output.finish

        expect(File.exist?(file_path_without_timestamp)).to be true

        csv_content = CSV.read(file_path_without_timestamp)

        expect(csv_content.first).to eq(%w[name setting description])

        block_size_row = csv_content.find { |row| row[0] == 'block_size' }

        expect(block_size_row).not_to be_nil
        # NOTE: 8192 bytes is the default value for the block size in Postgres so
        # it's safe to say this value will not change for us.
        expect(block_size_row[1]).to eq('8192')
      end

      it 'creates a CSV file with the correct headers and data (if applicable) with timestamps' do
        handler.write_to_csv(queries.keys.last, result_with_timestamp, include_timestamp: true)
        output.finish

        expect(File.exist?(file_path_with_timestamp)).to be true

        csv_content = CSV.read(file_path_with_timestamp)

        expect(csv_content.first).to include("timestamp", "relid", "schemaname")
      end
    end

    context 'when result is empty' do
      let(:empty_result) { [] }

      it 'creates an empty CSV file without timestamp' do
        handler.write_to_csv(queries.each_key.first, empty_result)
        output.finish

        expect(File.exist?(file_path_without_timestamp)).to be true
        expect(File.zero?(file_path_without_timestamp)).to be true
      end

      it 'creates an empty CSV file with timestamp' do
        handler.write_to_csv(queries.keys.last, empty_result, include_timestamp: true)
        output.finish

        expect(File.exist?(file_path_with_timestamp)).to be true
        expect(File.zero?(file_path_with_timestamp)).to be true
      end
    end

    context 'when an error occurs' do
      before do
        allow(output).to receive(:write_file).and_raise(StandardError.new('Something went wrong'))
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error) do |message|
          expect(message).to include("Error writing CSV for DB:#{db_name} query:#{queries.each_key.first} ")
        end
        handler.write_to_csv(queries.each_key.first, result)
      end
    end
  end
end
