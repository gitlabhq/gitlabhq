# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::JsonMetadataLogger, feature_category: :api do
  subject(:route) { described_class.new }

  describe "#parameters" do
    let(:mock_request) { ActionDispatch::Request.new(env) }
    let(:env) { {} }

    describe 'with no JSON metadata' do
      it 'returns an empty hash' do
        expect(route.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'with JSON metadata in request env' do
      let(:metadata) do
        {
          total_elements: 15,
          max_array_count: 5,
          max_hash_count: 3,
          max_depth: 2
        }
      end

      before do
        env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY] = metadata
      end

      it 'returns the metadata with json_ prefix' do
        result = route.parameters(mock_request, nil)

        expect(result).to eq({
          'json_total_elements' => 15,
          'json_max_array_count' => 5,
          'json_max_hash_count' => 3,
          'json_max_depth' => 2
        })
      end

      it 'transforms all keys with json_ prefix' do
        result = route.parameters(mock_request, nil)

        expect(result.keys).to all(start_with('json_'))
      end
    end

    describe 'with empty metadata hash' do
      before do
        env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY] = {}
      end

      it 'returns an empty hash' do
        expect(route.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'with partial metadata' do
      let(:metadata) do
        {
          total_elements: 10,
          max_depth: 1
        }
      end

      before do
        env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY] = metadata
      end

      it 'returns only the available metadata with json_ prefix' do
        result = route.parameters(mock_request, nil)

        expect(result).to eq({
          'json_total_elements' => 10,
          'json_max_depth' => 1
        })
      end
    end

    describe 'with nil metadata' do
      before do
        env[::Gitlab::Middleware::JsonValidation::RACK_ENV_METADATA_KEY] = nil
      end

      it 'returns an empty hash' do
        expect(route.parameters(mock_request, nil)).to eq({})
      end
    end
  end
end
