# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::ObjectStorage, feature_category: :importers do
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

  describe '#initialize' do
    context 'when the provider is aws' do
      let(:provider) { :aws }

      it 'builds an AWS adapter' do
        expect(described_class::Adapters::Aws).to receive(:new)
          .with(provider: provider, bucket: bucket, credentials: credentials)

        client
      end
    end

    context 'when the provider is s3_compatible' do
      let(:provider) { :s3_compatible }

      it 'builds an AWS adapter' do
        expect(described_class::Adapters::Aws).to receive(:new)
          .with(provider: provider, bucket: bucket, credentials: credentials)

        client
      end
    end

    context 'when the provider is gcs_hmac' do
      let(:provider) { :gcs_hmac }

      it 'builds a GCS HMAC adapter' do
        expect(described_class::Adapters::GcsHmac).to receive(:new)
          .with(provider: provider, bucket: bucket, credentials: credentials)

        client
      end
    end

    context 'when the provider is gcs' do
      let(:provider) { :gcs }

      it 'builds a GCS adapter' do
        expect(described_class::Adapters::Gcs).to receive(:new)
          .with(provider: provider, bucket: bucket, credentials: credentials)

        client
      end
    end

    context 'when the provider is unsupported' do
      let(:provider) { :unknown }

      it 'raises an ArgumentError' do
        expect { client }
          .to raise_error(ArgumentError, 'Unsupported object storage provider: unknown')
      end
    end
  end

  describe 'delegation to the adapter' do
    let(:provider) { :aws }
    let(:adapter) { instance_double(described_class::Adapters::Aws) }

    before do
      allow(described_class::Adapters::Aws).to receive(:new).and_return(adapter)
    end

    it 'delegates #request_url' do
      object_key = 'exports/project_1/issues.ndjson.gz'

      expect(adapter).to receive(:request_url).with(object_key)

      client.request_url(object_key)
    end

    it 'delegates #test_connection!' do
      expect(adapter).to receive(:test_connection!)

      client.test_connection!
    end

    it 'delegates #object_keys_for_prefix' do
      prefix = 'exports/group_1/labels'

      expect(adapter).to receive(:object_keys_for_prefix).with(prefix)

      client.object_keys_for_prefix(prefix)
    end

    it 'delegates #store_file' do
      object_key = 'exports/project_1/issues.ndjson.gz'
      local_path = 'spec/fixtures/bulk_imports/gz/labels.ndjson.gz'

      expect(adapter).to receive(:store_file).with(object_key, local_path)

      client.store_file(object_key, local_path)
    end

    it 'delegates #stream' do
      object_key = 'exports/project_1/issues.ndjson.gz'

      expect(adapter).to receive(:stream).with(object_key)

      client.stream(object_key)
    end
  end
end
