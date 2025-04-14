# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Sos::PlatformConfigInfo, feature_category: :database do
  let(:temp_directory) { Dir.mktmpdir }
  let(:output) { Gitlab::Database::Sos::Output.new(temp_directory, mode: :directory) }
  let(:db_name) { 'test_db' }
  let(:connection) { ApplicationRecord.connection }
  let(:handler) { described_class.new(connection, db_name, output) }
  let(:file_path) { File.join(temp_directory, db_name, "platform_config_info.csv") }

  after do
    FileUtils.remove_entry(temp_directory)
  end

  describe '#run' do
    context "when query results and config info exists" do
      it 'successfully writes to CSV' do
        handler.run

        expect(File.exist?(file_path)).to be true
        csv_content = CSV.read(file_path)
        expect(csv_content.first).to eq(%w[source key value])
      end

      it "excludes sensitive information" do
        config_with_sensitive = { username: 'test_user', password: 'secret', host: 'localhost' }

        db_config = connection.pool.db_config

        # Stub the config because the test db object has been created before the test
        allow(db_config).to receive(:configuration_hash).and_return(config_with_sensitive)

        handler.run

        csv_content = CSV.read(file_path)
        config_rows = csv_content.select { |row| row[0] == 'config' }
        config_keys = config_rows.pluck(1)
        expect(config_keys).not_to include('username')
        expect(config_keys).not_to include('password')
      end
    end

    context 'when an error occurs' do
      let(:message)  { "Something went wrong" }

      before do
        allow(output).to receive(:write_file).and_raise(StandardError.new(message))
      end

      it 'logs the error' do
        expected_error = "Error writing platform config info for DB:#{db_name} " \
          "with error message:#{message}"
        expect(Gitlab::AppLogger).to receive(:error).with(expected_error)

        handler.run
      end
    end
  end
end
