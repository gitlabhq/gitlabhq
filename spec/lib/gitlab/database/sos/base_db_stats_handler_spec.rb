# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::BaseDbStatsHandler, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:output_file_path) { temp_directory }
  let(:expected_file_path) { File.join(output_file_path, db_name, "#{query.each_key.first}.csv") }
  let(:output) { Gitlab::Database::Sos::Output.new(output_file_path, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }
  let(:query) { { pg_show_all_settings: "SHOW ALL;" } }
  let(:result) { ApplicationRecord.connection.execute(query[:pg_show_all_settings]) }

  before do
    allow(Gitlab::Database::Sos::DbStatsActivity).to receive(:queries).and_return({
      pg_show_all_settings: 'SHOW ALL;'
    })
  end

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
        result = handler.execute_query(query[:pg_show_all_settings])
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
    context 'when result exists' do
      it 'creates a CSV file with the correct headers and data (if applicable)' do
        handler.write_to_csv(query.each_key.first, result)
        output.finish

        expect(File.exist?(expected_file_path)).to be true

        csv_content = CSV.read(expected_file_path)

        expect(csv_content.first).to eq(%w[name setting description])

        block_size_row = csv_content.find { |row| row[0] == 'block_size' }

        expect(block_size_row).not_to be_nil
        # NOTE: 8192 bytes is the default value for the block size in Postgres so
        # it's safe to say this value will not change for us.
        expect(block_size_row[1]).to eq('8192')
      end
    end

    context 'when result is empty' do
      let(:empty_result) { [] }

      it 'creates an empty CSV file' do
        handler.write_to_csv(query.each_key.first, empty_result)
        output.finish

        expect(File.exist?(expected_file_path)).to be true
        expect(File.zero?(expected_file_path)).to be true
      end
    end

    context 'when an error occurs' do
      before do
        allow(output).to receive(:write_file).and_raise(StandardError.new('Something went wrong'))
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error) do |message|
          expect(message).to include("Error writing CSV for DB:#{db_name} query:#{query.each_key.first} error message")
        end
        handler.write_to_csv(query.each_key.first, result)
      end
    end
  end
end
