# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Capture::Storage, feature_category: :database do
  let(:filename) { 'wal_capture' }
  let(:storage) { described_class.new }
  let(:local_connector) { instance_double(Gitlab::Database::Capture::StorageConnectors::Local, upload: true) }
  let(:gcs_connector) { instance_double(Gitlab::Database::Capture::StorageConnectors::Gcs, upload: true) }
  let(:configured_settings) { {} }
  let(:data) do
    <<~NDJSON
      {"id": 1, "sql": "SELECT 1 FROM \"public\".\"users\" LIMIT 1;"}
      {"id": 2, "sql": "SELECT * FROM \"public\".\"projects\" WHERE \"projects\".\"id\" = 1;"}
      {"id": 3, "sql": "DELETE FROM \"public\".\"users\" WHERE \"users\".\"id\" = 1;"}
    NDJSON
  end

  before do
    allow(Gitlab::AppLogger).to receive(:info)
    allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(0.0, 1.5)
    allow(Gitlab::Database::Capture::StorageConnectors::Local).to receive(:new).and_return(local_connector)
    allow(Gitlab::Database::Capture::StorageConnectors::Gcs).to receive(:new).and_return(gcs_connector)

    allow(Settings).to(
      receive_message_chain(:database_traffic_capture, :config, :storage, :connector).and_return(
        GitlabSettings::Options.build(configured_settings)
      )
    )
  end

  describe '#upload' do
    context 'when using Google connector' do
      let(:configured_settings) do
        {
          provider: 'Gcs',
          project_id: 'my-project',
          bucket: 'my-bucket'
        }
      end

      it 'uses the GCS connector' do
        expect(Gitlab::Database::Capture::StorageConnectors::Gcs).to(
          receive(:new).with(Settings.database_traffic_capture.config.storage.connector).and_return(gcs_connector)
        )
        expect(gcs_connector).to receive(:upload).with(filename, data)

        storage.upload(filename, data)
      end

      it 'logs the upload request and completion' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: 'Upload request for database capture',
            connector: 'Gcs',
            filename: filename,
            duration: nil
          }.compact
        )

        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: 'Database capture upload completed',
            connector: 'Gcs',
            filename: filename,
            duration: 1.5
          }.compact
        )

        storage.upload(filename, data)
      end
    end

    context 'when Settings are not configured' do
      it 'falls back to Local connector' do
        expect(Gitlab::Database::Capture::StorageConnectors::Local).to(
          receive(:new).with(Settings.database_traffic_capture.config.storage.connector).and_return(local_connector)
        )
        expect(local_connector).to receive(:upload).with(filename, data)

        storage.upload(filename, data)
      end
    end

    context 'when the connection fails to upload the file' do
      let(:configured_settings) do
        {
          provider: 'Gcs',
          project_id: 'my-project',
          bucket: 'my-bucket'
        }
      end

      before do
        allow(gcs_connector).to receive(:upload).and_raise(StandardError, 'GCS unavailable.')
      end

      it 'logs the message and re-raise the error' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            message: 'Database capture upload failed: GCS unavailable.',
            connector: 'Gcs',
            filename: filename,
            duration: nil
          }.compact
        )

        expect { storage.upload(filename, data) }.to raise_error('GCS unavailable.')
      end
    end
  end
end
