# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::ObjectStorage::Adapters::Gcs, feature_category: :importers do
  let(:provider) { :gcs }
  let(:bucket) { 'gitlab-exports' }
  let(:credentials) do
    {
      google_project: 'gitlab-project',
      type: 'service_account',
      project_id: 'gitlab-project',
      private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
      client_email: 'gcs@gitlab-project.iam.gserviceaccount.com'
    }
  end

  let(:fog_credentials) do
    {
      provider: 'Google',
      google_project: 'gitlab-project',
      google_json_key_string: Gitlab::Json.dump(credentials.except(:google_project)),
      universe_domain: described_class::GOOGLE_DEFAULT_UNIVERSE_DOMAIN
    }
  end

  subject(:adapter) { described_class.new(provider: provider, bucket: bucket, credentials: credentials) }

  before do
    Fog.mock!
    Fog::Storage.new(provider: 'Google', google_project: 'gitlab-project', google_json_key_string: '{}')
  end

  describe '#request_url' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }

    it 'builds the canonical GCS object URL from the connection host' do
      expect(adapter.request_url(object_key)).to eq(
        "https://storage.googleapis.com/#{bucket}/#{object_key}"
      )
    end
  end

  describe '#test_connection!' do
    context 'when the bucket is accessible' do
      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:get_bucket).with(bucket).and_return(Google::Apis::StorageV1::Bucket.new)
        end
      end

      it 'does not raise an error' do
        expect { adapter.test_connection! }.not_to raise_error
      end

      it 'builds a fog-google connection with the JSON key rebuilt from the flattened credentials' do
        fog_storage = instance_double(Fog::Google::StorageJSON::Mock, get_bucket: Google::Apis::StorageV1::Bucket.new)
        allow(Fog::Storage).to receive(:new).and_return(fog_storage)

        adapter.test_connection!

        expect(Fog::Storage).to have_received(:new).with(fog_credentials)
      end

      it 'pins the connection to the default Google Cloud universe domain' do
        fog_storage = instance_double(Fog::Google::StorageJSON::Mock, get_bucket: Google::Apis::StorageV1::Bucket.new)
        allow(Fog::Storage).to receive(:new).and_return(fog_storage)

        adapter.test_connection!

        expect(Fog::Storage).to have_received(:new).with(hash_including(universe_domain: 'googleapis.com'))
      end
    end

    context 'when the bucket is not accessible' do
      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:get_bucket).with(bucket).and_return(nil)
        end
      end

      it 'raises ConnectionError' do
        expect { adapter.test_connection! }.to raise_error(
          Import::Clients::ObjectStorage::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end

    context 'when Google::Apis::Error is raised' do
      let(:api_error) { Google::Apis::Error.new('not found') }

      before do
        allow_next_instance_of(Fog::Storage) do |storage|
          allow(storage).to receive(:get_bucket).and_raise(api_error)
        end
      end

      it 'tracks the exception and raises ConnectionError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          api_error,
          provider: provider,
          bucket: bucket
        )

        expect { adapter.test_connection! }.to raise_error(
          Import::Clients::ObjectStorage::ConnectionError, 'Unable to access object storage bucket.'
        )
      end
    end
  end

  describe '#store_file' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:local_path) { 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz' }
    let(:files) { instance_double(Fog::Google::StorageJSON::Files) }
    let(:directory) { instance_double(Fog::Google::StorageJSON::Directory, files: files) }
    let(:directories) { instance_double(Fog::Google::StorageJSON::Directories, new: directory) }

    before do
      allow_next_instance_of(Fog::Storage) do |storage|
        allow(storage).to receive(:directories).and_return(directories)
      end
    end

    it 'uploads the file through the fog-google JSON backend' do
      expect(files).to receive(:create).with(
        hash_including(
          key: object_key,
          body: anything,
          multipart_chunk_size: Import::Clients::ObjectStorage::MULTIPART_THRESHOLD
        )
      ).and_return(true)

      expect(adapter.store_file(object_key, local_path)).to be true
    end
  end

  describe '#stream' do
    let(:object_key) { 'exports/project_1/issues.ndjson.gz' }
    let(:files) { instance_double(Fog::Google::StorageJSON::Files) }
    let(:directory) { instance_double(Fog::Google::StorageJSON::Directory, files: files) }
    let(:directories) { instance_double(Fog::Google::StorageJSON::Directories, new: directory) }

    before do
      allow_next_instance_of(Fog::Storage) do |storage|
        allow(storage).to receive(:directories).and_return(directories)
      end
    end

    context 'when the object exists' do
      it 'yields chunks, remaining bytes and total bytes to the block', :aggregate_failures do
        expect(files).to receive(:get).with(object_key)
          .and_yield('chunk', 0, 5)
          .and_return(instance_double(Fog::Google::StorageJSON::File))

        chunks = []
        remaining_values = []
        total_values = []

        adapter.stream(object_key) do |chunk, remaining, total|
          chunks << chunk
          remaining_values << remaining
          total_values << total
        end

        expect(chunks).to eq(['chunk'])
        expect(remaining_values).to eq([0])
        expect(total_values).to eq([5])
      end
    end

    context 'when the object does not exist' do
      it 'raises DownloadError' do
        expect(files).to receive(:get).with(object_key).and_return(nil)

        expect { adapter.stream(object_key) { |c| c } }.to raise_error(
          Import::Clients::ObjectStorage::DownloadError, 'Object not found'
        )
      end
    end
  end

  describe '#object_keys_for_prefix' do
    let(:object_key_prefix) { 'exports/group_1/labels' }
    let(:object_keys) { ['exports/group_1/labels/batch_1.ndjson.gz', 'exports/group_1/labels/batch_2.ndjson.gz'] }
    let(:files) { instance_double(Fog::Google::StorageJSON::Files) }
    let(:directory) { instance_double(Fog::Google::StorageJSON::Directory, files: files) }
    let(:directories) { instance_double(Fog::Google::StorageJSON::Directories, new: directory) }

    before do
      allow_next_instance_of(Fog::Storage) do |storage|
        allow(storage).to receive(:directories).and_return(directories)
      end
      allow(files).to receive(:prefix=)
      allow(files).to receive(:map).and_return(object_keys)
    end

    it 'paginates using the shared page size and returns the object keys' do
      expect(files).to receive(:max_results=).with(Import::Clients::ObjectStorage::LIST_OBJECT_KEYS_PAGE_SIZE)

      expect(adapter.object_keys_for_prefix(object_key_prefix)).to eq(object_keys)
    end
  end
end
