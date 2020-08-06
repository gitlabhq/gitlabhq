# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::Errors do
  describe Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError do
    context 'valid error hash from jsonschemer' do
      let(:error_hash) do
        {
          'data'            => 'data',
          'data_pointer'    => 'data_pointer',
          'schema'          => 'schema',
          'schema_pointer'  => 'schema_pointer'
        }
      end

      it 'formats message' do
        expect(described_class.new(error_hash).message).to eq(
          "'data' is invalid at 'data_pointer'. Should be 'schema' due to schema definition at 'schema_pointer'"
        )
      end
    end

    context 'empty error hash' do
      let(:error_hash) { {} }

      it 'uses default error message' do
        expect(described_class.new(error_hash).message).to eq('Dashboard failed schema validation')
      end
    end
  end

  describe Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds do
    it 'has custom error message' do
      expect(described_class.new.message).to eq('metric_id must be unique across a project')
    end
  end
end
