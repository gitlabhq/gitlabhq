# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::ObjectStorage, feature_category: :importers do
  let(:provider) { :aws }
  let(:bucket) { 'gitlab_exports' }
  let(:credentials) do
    {
      aws_access_key_id: 'AwsUserAccessKey',
      aws_secret_access_key: 'aws/secret+access/key',
      region: 'us-east-1',
      path_style: false
    }
  end

  subject(:client) { described_class.new(provider: provider, bucket: bucket, credentials: credentials) }

  describe '#test_connection!' do
    before do
      allow_next_instance_of(Fog::Storage) do |storage|
        allow(storage).to receive(:head_bucket).and_return(
          Excon::Response.new(status: http_status)
        )
      end
    end

    context 'when the object storage bucket responds with status 200' do
      let(:http_status) { 200 }

      it 'does not raise an error' do
        expect { client.test_connection! }.not_to raise_error
      end

      it 'sets AWS the fog provider option' do
        expect(Fog::Storage).to receive(:new).with(hash_including(provider: 'AWS'))

        client.test_connection!
      end

      context 'when provider is S3 compatible' do
        let(:provider) { :s3_compatible }

        it 'sets AWS the fog provider option' do
          expect(Fog::Storage).to receive(:new).with(hash_including(provider: 'AWS'))

          client.test_connection!
        end
      end
    end

    context 'when the object storage bucket responds with a status other than 200' do
      let(:http_status) { 302 }

      it 'raises an error' do
        expect { client.test_connection! }.to raise_error(
          described_class::ConnectionError, "Object storage request responded with status #{http_status}"
        )
      end
    end
  end

  describe '#store_file' do
    before do
      stub_object_storage(
        connection_params: { provider: provider }.merge(credentials),
        remote_directory: bucket
      )
    end

    let(:upload_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }

    context 'when the file exists and object storage is available' do
      it 'uploads file with streaming and multipart support' do
        expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
          expect(files).to receive(:create).with(
            hash_including(
              key: upload_key,
              body: anything,
              multipart_chunk_size: described_class::MULTIPART_THRESHOLD
            )
          ).and_call_original
        end

        expect(client.store_file(upload_key, local_path)).to be true
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(local_path).and_return(false)
      end

      it 'raises UploadError' do
        expect { client.store_file(upload_key, local_path) }
          .to raise_error(
            Import::Clients::ObjectStorage::UploadError,
            "File not found: #{local_path}"
          )
      end
    end

    context 'when directory traversal is attempted' do
      let(:local_path) { 'spec/../../../../etc/passwd' }

      it 'raises an exception' do
        expect { client.store_file(upload_key, local_path) }
          .to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end

    context 'when Fog raises an error' do
      let(:fog_error) { Fog::Errors::Error.new('S3 connection timeout') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:directories).and_raise(fog_error)
        end
      end

      it 'tracks exception and raises UploadError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          fog_error,
          provider: provider,
          bucket: bucket,
          upload_key: upload_key,
          local_path: local_path
        )

        expect { client.store_file(upload_key, local_path) }
          .to raise_error(
            Import::Clients::ObjectStorage::UploadError,
            'Object storage upload failed: S3 connection timeout'
          )
      end
    end
  end
end
