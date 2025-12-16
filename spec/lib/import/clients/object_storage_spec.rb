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

      context 'when provider is MinIO' do
        let(:provider) { :minio }

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
end
