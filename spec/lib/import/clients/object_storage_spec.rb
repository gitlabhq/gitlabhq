# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::ObjectStorage, feature_category: :importers do
  let(:provider) { :aws }
  let(:bucket) { 'gitlab-exports' }
  let(:credentials) do
    {
      aws_access_key_id: 'AwsUserAccessKey',
      aws_secret_access_key: 'aws/secret+access/key',
      region: 'us-east-2',
      path_style: false
    }
  end

  subject(:client) { described_class.new(provider: provider, bucket: bucket, credentials: credentials) }

  describe '#request_url' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }

    it 'returns the Fog storage request_url' do
      expect_next_instance_of(Fog::Storage) do |storage|
        expect(storage).to receive(:request_url).with(bucket_name: bucket, object_name: object_key).and_call_original
      end

      expect(client.request_url(object_key)).to eq(
        "https://#{bucket}.s3.#{credentials[:region]}.amazonaws.com/#{object_key}"
      )
    end
  end

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

      it 'raises ConnectionError' do
        expect { client.test_connection! }.to raise_error(
          described_class::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end

    context 'when Excon raises an error' do
      let(:http_status) { 200 }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_raise(Excon::Error, 'socket timeout')
        end
      end

      it 'raises ConnectionError' do
        expect { client.test_connection! }.to raise_error(
          described_class::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end

    context 'when Fog raises an error' do
      let(:http_status) { 200 }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_raise(Fog::Errors::Error, 'connection refused')
        end
      end

      it 'raises ConnectionError' do
        expect { client.test_connection! }.to raise_error(
          described_class::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end

    context 'when a NoMethodError is raised with an Excon::Error cause' do
      let(:http_status) { 200 }
      let(:excon_error) { Excon::Error.new('redirect') }
      let(:no_method_error) do
        NoMethodError.new('undefined method').tap do |e|
          allow(e).to receive(:cause).and_return(excon_error)
        end
      end

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_raise(no_method_error)
        end
      end

      it 'tracks the exception and raises ConnectionError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          no_method_error,
          provider: provider,
          bucket: bucket
        )

        expect { client.test_connection! }.to raise_error(
          described_class::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end

    context 'when a NoMethodError is raised with a non-Excon cause' do
      let(:http_status) { 200 }
      let(:no_method_error) { NoMethodError.new('undefined method `foo`') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:head_bucket).and_raise(no_method_error)
        end
      end

      it 're-raises the original NoMethodError' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        expect { client.test_connection! }.to raise_error(no_method_error)
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

    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }

    context 'when the file exists and object storage is available' do
      it 'uploads file with streaming and multipart support' do
        expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
          expect(files).to receive(:create).with(
            hash_including(
              key: object_key,
              body: anything,
              multipart_chunk_size: described_class::MULTIPART_THRESHOLD
            )
          ).and_call_original
        end

        expect(client.store_file(object_key, local_path)).to be true
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(local_path).and_return(false)
      end

      it 'raises UploadError' do
        expect { client.store_file(object_key, local_path) }
          .to raise_error(
            Import::Clients::ObjectStorage::UploadError,
            "File not found: #{local_path}"
          )
      end
    end

    context 'when directory traversal is attempted' do
      let(:local_path) { 'spec/../../../../etc/passwd' }

      it 'raises an exception' do
        expect { client.store_file(object_key, local_path) }
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
          object_key: object_key,
          local_path: local_path
        )

        expect { client.store_file(object_key, local_path) }
          .to raise_error(Import::Clients::ObjectStorage::UploadError, 'Object storage upload failed')
      end
    end
  end

  describe '#stream' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }

    before do
      stub_object_storage(
        connection_params: { provider: provider }.merge(credentials),
        remote_directory: bucket
      )
    end

    context 'when the object exists' do
      before do
        client.store_file(object_key, local_path)
      end

      it 'yields chunks, remaining bytes and total bytes to the block', :aggregate_failures do
        chunks = []
        remaining_values = []
        total_values = []

        client.stream(object_key) do |chunk, remaining, total|
          chunks << chunk
          remaining_values << remaining
          total_values << total
        end

        expect(chunks).not_to be_empty
        expect(total_values).to all(be_a(Integer).and(be > 0))
        expect(remaining_values).to all(be_a(Integer).and(be >= 0))
      end
    end

    context 'when the object does not exist' do
      it 'raises DownloadError' do
        expect { client.stream('nonexistent/key') }.to raise_error(
          Import::Clients::ObjectStorage::DownloadError, 'Object not found'
        )
      end
    end

    context 'when Fog raises an error' do
      let(:fog_error) { Fog::Errors::Error.new('connection refused') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:directories).and_raise(fog_error)
        end
      end

      it 'tracks exception and raises DownloadError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          fog_error,
          provider: provider,
          bucket: bucket,
          object_key: object_key
        )

        expect { client.stream(object_key) { |c| c } }.to raise_error(
          described_class::DownloadError, 'Object storage download failed'
        )
      end
    end

    context 'when Excon raises an error' do
      let(:excon_error) { Excon::Error.new('socket timeout') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:directories).and_raise(excon_error)
        end
      end

      it 'tracks exception and raises DownloadError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          excon_error,
          provider: provider,
          bucket: bucket,
          object_key: object_key
        )

        expect { client.stream(object_key) { |c| c } }.to raise_error(
          described_class::DownloadError, 'Object storage download failed'
        )
      end
    end
  end

  describe '#object_keys_for_prefix' do
    let(:object_key_prefix) { 'exports/group_1/labels' }
    let(:storage) { Fog::Storage.new(provider: 'AWS', **credentials) }
    let(:directory) { storage.directories.new(key: bucket) }
    let(:object_keys) { [] }

    before do
      stub_object_storage(
        connection_params: { provider: provider }.merge(credentials),
        remote_directory: bucket
      )

      object_keys.each do |key|
        directory.files.create(key: key, body: 'file content') # rubocop:disable Rails/SaveBang -- fog file collections do not use ActiveRecord
      end
    end

    context 'when objects exist under the prefix' do
      let(:object_keys) do
        [
          "#{object_key_prefix}/batch_1.ndjson.gz",
          "#{object_key_prefix}/batch_2.ndjson.gz",
          "#{object_key_prefix}.ndjson.gz"
        ]
      end

      it 'returns the object keys' do
        result = client.object_keys_for_prefix(object_key_prefix)

        expect(result).to match_array(object_keys)
      end
    end

    context 'when no objects exist under the prefix' do
      it 'returns an empty array' do
        expect(client.object_keys_for_prefix(object_key_prefix)).to be_empty
      end
    end

    context 'when Fog raises an error' do
      let(:fog_error) { Fog::Errors::Error.new('connection refused') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:directories).and_raise(fog_error)
        end
      end

      it 'tracks exception and raises ConnectionError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          fog_error,
          provider: provider,
          bucket: bucket,
          object_key_prefix: object_key_prefix
        )

        expect { client.object_keys_for_prefix(object_key_prefix) }.to raise_error(
          described_class::ConnectionError, 'Unable to list objects in prefix'
        )
      end
    end

    context 'when Excon raises an error' do
      let(:excon_error) { Excon::Error.new('socket timeout') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:directories).and_raise(excon_error)
        end
      end

      it 'tracks exception and raises DownloadError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          excon_error,
          provider: provider,
          bucket: bucket,
          object_key_prefix: object_key_prefix
        )

        expect { client.object_keys_for_prefix(object_key_prefix) }.to raise_error(
          described_class::ConnectionError, 'Unable to list objects in prefix'
        )
      end
    end
  end
end
