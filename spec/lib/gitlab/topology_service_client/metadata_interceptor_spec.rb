# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::MetadataInterceptor, feature_category: :cell do
  subject(:interceptor) { described_class.new }

  describe '#request_response' do
    let(:metadata) { {} }
    let(:config_metadata) do
      {
        'key1' => 'val1',
        'key2' => 'val2'
      }
    end

    before do
      stub_config(cell: {
        topology_service_client: {
          metadata: config_metadata
        }
      })
    end

    it 'adds configured metadata to the request metadata' do
      interceptor.request_response(metadata: metadata) {} # rubocop:disable Lint/EmptyBlock -- Intentionally empty

      expect(metadata).to include(config_metadata)
    end

    context 'when config metadata is empty' do
      let(:config_metadata) { {} }

      it 'does not modify the metadata' do
        original_metadata = metadata.dup

        interceptor.request_response(metadata: metadata) {} # rubocop:disable Lint/EmptyBlock -- Intentionally empty

        expect(metadata).to eq(original_metadata)
      end
    end
  end
end
