# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::SnowplowContextValidator, feature_category: :application_instrumentation do
  subject(:validator) { described_class.new }

  let(:valid_schema_url) { 'iglu:com.gitlab/gitlab_standard/jsonschema/1-1-7' }
  let(:valid_data) { { 'environment' => 'test', 'source' => 'gitlab-rails' } }
  let(:valid_context) { { schema: valid_schema_url, data: valid_data } }

  describe '#validate!' do
    let(:schema_definition) do
      {
        'type' => 'object',
        'properties' => {
          'environment' => { 'type' => 'string' },
          'source' => { 'type' => 'string' }
        }
      }
    end

    before do
      stub_request(:get, "https://gitlab-org.gitlab.io/iglu/schemas/#{valid_schema_url.delete_prefix('iglu:')}")
        .to_return(status: 200, body: schema_definition.to_json)
    end

    context 'with a valid hash context' do
      it 'does not raise an error' do
        expect { validator.validate!(valid_context) }.not_to raise_error
      end
    end

    context 'with an array of contexts' do
      let(:contexts) { [valid_context, valid_context] }

      it 'validates each context in the array' do
        expect { validator.validate!(contexts) }.not_to raise_error
      end
    end

    context 'with nil context' do
      it 'returns early without error' do
        expect { validator.validate!(nil) }.not_to raise_error
      end
    end
  end

  describe 'schema validation', :freeze_time do
    let(:schema_definition) do
      {
        'type' => 'object',
        'properties' => {
          'environment' => { 'type' => 'string' },
          'source' => { 'type' => 'string' }
        },
        'required' => %w[environment source]
      }
    end

    before do
      stub_request(:get, "https://gitlab-org.gitlab.io/iglu/schemas/#{valid_schema_url.delete_prefix('iglu:')}")
        .to_return(status: 200, body: schema_definition.to_json)
    end

    context 'when data matches the schema' do
      it 'does not raise an error' do
        expect { validator.validate!(valid_context) }.not_to raise_error
      end
    end

    context 'when data does not match the schema' do
      let(:invalid_data) { { 'invalid_field' => 'value' } }
      let(:invalid_context) { { schema: valid_schema_url, data: invalid_data } }

      it 'tracks the validation error' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(an_instance_of(ArgumentError), hash_including(:schema_url, :validation_errors))

        validator.validate!(invalid_context)
      end
    end
  end

  describe 'schema fetching from Iglu' do
    let(:iglu_url) { "https://gitlab-org.gitlab.io/iglu/schemas/com.gitlab/gitlab_standard/jsonschema/1-1-7" }
    let(:schema_definition) { { 'type' => 'object' } }

    context 'when schema fetch succeeds' do
      before do
        stub_request(:get, iglu_url)
          .to_return(status: 200, body: schema_definition.to_json)
      end

      it 'fetches and validates against the schema' do
        expect { validator.validate!(valid_context) }.not_to raise_error
      end

      it 'caches the schema for subsequent requests', :use_clean_rails_memory_store_caching do
        # First request - should hit the HTTP endpoint
        validator.validate!(valid_context)
        expect(WebMock).to have_requested(:get, iglu_url).once

        # Second request - should use cached schema
        validator.validate!(valid_context)
        expect(WebMock).to have_requested(:get, iglu_url).once # Still only once
      end

      it 'excludes $schema field from the schema definition' do
        schema_with_meta = schema_definition.merge('$schema' => 'http://json-schema.org/draft-07/schema#')

        stub_request(:get, iglu_url)
          .to_return(status: 200, body: schema_with_meta.to_json)

        expect { validator.validate!(valid_context) }.not_to raise_error
      end
    end

    context 'when schema fetch fails' do
      before do
        stub_request(:get, iglu_url)
          .to_return(status: 500)
      end

      it 'does not raise an error' do
        expect { validator.validate!(valid_context) }.not_to raise_error
      end

      it 'logs the error' do
        expect(Gitlab::AppJsonLogger).to receive(:warn).with(
          message: 'Failed to fetch Snowplow schema from Iglu registry',
          status_code: 500,
          schema_url: valid_schema_url
        )

        validator.validate!(valid_context)
      end
    end
  end
end
