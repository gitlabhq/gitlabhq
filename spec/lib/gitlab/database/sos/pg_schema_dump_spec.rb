# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::PgSchemaDump, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:output) { Gitlab::Database::Sos::Output.new(temp_directory, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }
  let(:file) { instance_double(File) }

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

  describe '#run' do
    it 'successfully writes the schema dump results to an sql file' do
      relative_file_path = "#{db_name}/#{db_name}_schema_dump.sql"
      File.join(temp_directory, relative_file_path)

      expect(output).to receive(:write_file).with(relative_file_path).and_yield(StringIO.new)
      expect(File).to receive(:open).with(instance_of(StringIO), 'w').and_return(:file)

      handler.run
    end

    context 'when an error occurs' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(output).to receive(:write_file).and_raise(StandardError.new(error_message))
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          "Error writing schema dump for DB:#{db_name} " \
            "with error message:#{error_message}"
        )

        handler.run
      end
    end
  end
end
