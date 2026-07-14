# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::ObjectStorage::Adapters::GcsHmac, feature_category: :importers do
  let(:provider) { :gcs_hmac }
  let(:bucket) { 'gitlab-exports' }
  let(:credentials) do
    {
      google_storage_access_key_id: 'GOOG1EXAMPLEACCESSKEY123',
      google_storage_secret_access_key: 'AbCd+EfGh/IjKlMnOpQrStUvWxYz0123456789K=', # gitleaks:allow
      region: 'us-east1',
      path_style: true
    }
  end

  # The fog-aws connection params the adapter derives from the GCS HMAC credentials.
  let(:fog_credentials) do
    {
      provider: 'AWS',
      aws_access_key_id: 'GOOG1EXAMPLEACCESSKEY123',
      aws_secret_access_key: 'AbCd+EfGh/IjKlMnOpQrStUvWxYz0123456789K=', # gitleaks:allow
      region: 'us-east1',
      path_style: true,
      endpoint: described_class::GCS_S3_ENDPOINT
    }
  end

  subject(:adapter) { described_class.new(provider: provider, bucket: bucket, credentials: credentials) }

  describe '#request_url' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }

    it 'targets the official GCS S3-interoperability endpoint' do
      expect_next_instance_of(Fog::Storage) do |storage|
        expect(storage).to receive(:request_url).with(bucket_name: bucket, object_name: object_key).and_call_original
      end

      expect(adapter.request_url(object_key)).to eq(
        "#{described_class::GCS_S3_ENDPOINT}/#{bucket}/#{object_key}"
      )
    end
  end

  describe '#test_connection!' do
    let(:fog_storage) do
      Class.new do
        def head_bucket(_bucket)
          Excon::Response.new(status: 200)
        end
      end.new
    end

    before do
      allow(Fog::Storage).to receive(:new).and_return(fog_storage)
    end

    it 'builds a fog-aws connection against the GCS endpoint with translated credentials' do
      adapter.test_connection!

      expect(Fog::Storage).to have_received(:new).with(fog_credentials)
    end

    context 'when path_style is omitted' do
      let(:credentials) do
        {
          google_storage_access_key_id: 'GOOG1EXAMPLEACCESSKEY123',
          google_storage_secret_access_key: 'AbCd+EfGh/IjKlMnOpQrStUvWxYz0123456789K=', # gitleaks:allow
          region: 'us-east1'
        }
      end

      it 'defaults path_style to true' do
        adapter.test_connection!

        expect(Fog::Storage).to have_received(:new).with(hash_including(path_style: true))
      end
    end
  end

  describe '#store_file' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }

    before do
      stub_object_storage(connection_params: fog_credentials, remote_directory: bucket)
    end

    it 'uploads the file through the GCS endpoint' do
      expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
        expect(files).to receive(:create).with(
          hash_including(
            key: object_key,
            body: anything,
            multipart_chunk_size: Import::Clients::ObjectStorage::MULTIPART_THRESHOLD
          )
        ).and_call_original
      end

      expect(adapter.store_file(object_key, local_path)).to be true
    end
  end

  describe '#stream' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }

    before do
      stub_object_storage(connection_params: fog_credentials, remote_directory: bucket)
      adapter.store_file(object_key, local_path)
    end

    it 'yields chunks, remaining bytes and total bytes to the block', :aggregate_failures do
      chunks = []
      remaining_values = []
      total_values = []

      adapter.stream(object_key) do |chunk, remaining, total|
        chunks << chunk
        remaining_values << remaining
        total_values << total
      end

      expect(chunks).not_to be_empty
      expect(total_values).to all(be_a(Integer).and(be > 0))
      expect(remaining_values).to all(be_a(Integer).and(be >= 0))
    end
  end

  describe '#object_keys_for_prefix' do
    let(:object_key_prefix) { 'exports/group_1/labels' }
    let(:storage) { Fog::Storage.new(fog_credentials) }
    let(:directory) { storage.directories.new(key: bucket) }
    let(:object_keys) do
      [
        "#{object_key_prefix}/batch_1.ndjson.gz",
        "#{object_key_prefix}/batch_2.ndjson.gz",
        "#{object_key_prefix}.ndjson.gz"
      ]
    end

    before do
      stub_object_storage(connection_params: fog_credentials, remote_directory: bucket)

      object_keys.each do |key|
        directory.files.create(key: key, body: 'file content') # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord
      end
    end

    it 'returns the object keys under the prefix' do
      expect(adapter.object_keys_for_prefix(object_key_prefix)).to match_array(object_keys)
    end
  end
end
