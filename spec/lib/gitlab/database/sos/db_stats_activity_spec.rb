# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::DbStatsActivity, feature_category: :database do
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
      handler.run

      described_class::QUERIES.each_key do |name|
        file_path = File.join(temp_directory, db_name, "#{name}.csv")
        expect(File.exist?(file_path)).to be true
        expect(File.size(file_path)).to be > 0

        csv_content = CSV.read(file_path)
        expect(csv_content).not_to be_empty
        expect(csv_content.first).to be_an(Array)
      end
    end
  end

  describe 'individual queries' do
    described_class::QUERIES.each do |name, query|
      it "successfully executes and returns results for #{name}" do
        result = handler.execute_query(query)

        expect(result).to be_a(PG::Result)
        expect(result.nfields).to be > 0

        case name
        when :pg_constraints
          expect(result.fields).to eq %w[table_name constraint_name constraint_definition]
        when :pg_role_db_setting
          expect(result.fields).to eq %w[setdatabase setrole setconfig]
        when :read_replica_count
          expect(result.fields).to eq %w[replica_count]
        when :pg_show_all_settings
          expect(result.fields).to eq %w[name setting description]
        when :bbm_status
          expect(result.fields).to eq %w[job_class_name table_name column_name job_arguments]
        when :platform_info
          expect(result.fields).to eq %w[key value]
        when :collation_check
          expect(result.fields).to eq %w[collation_name version actual_version]
        when :pg_class_settings
          expect(result.fields).to include("oid", "relname", "relnamespace", "reltype")
        end
      end
    end
  end
end
