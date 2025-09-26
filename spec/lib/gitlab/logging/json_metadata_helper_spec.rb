# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Logging::JsonMetadataHelper, feature_category: :observability do
  let(:helper_class) do
    Class.new do
      include Gitlab::Logging::JsonMetadataHelper
    end
  end

  let(:helper) { helper_class.new }
  let(:payload) { {} }
  let(:request) { ActionDispatch::Request.new(env) }

  describe '#store_json_metadata_headers!' do
    context 'when JSON metadata is present in request env' do
      let(:env) do
        {
          ::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY => {
            total_elements: 100,
            max_array_count: 50,
            max_hash_count: 25,
            max_depth: 10
          }
        }
      end

      it 'adds JSON metadata to payload with json_ prefix' do
        helper.store_json_metadata_headers!(payload, request)

        expect(payload).to eq({
          json_total_elements: 100,
          json_max_array_count: 50,
          json_max_hash_count: 25,
          json_max_depth: 10
        })
      end
    end

    context 'when JSON metadata key is missing from request env' do
      let(:env) { {} }

      it 'does not add any metadata to payload' do
        helper.store_json_metadata_headers!(payload, request)

        expect(payload).to be_empty
      end
    end
  end
end
