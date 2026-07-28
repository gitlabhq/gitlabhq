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
    using RSpec::Parameterized::TableSyntax

    where(:provider, :expected_adapter) do
      :aws           | described_class::Adapters::Aws
      :s3_compatible | described_class::Adapters::Aws
      :gcs           | described_class::Adapters::Gcs
      :gcs_hmac      | described_class::Adapters::GcsHmac
    end

    with_them do
      it 'builds the adapter for the provider' do
        expect(expected_adapter).to receive(:new)
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
