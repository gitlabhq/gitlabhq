# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require_relative '../../../../../gems/gitlab-rspec/lib/gitlab/rspec/stub_env'
require_relative '../../../../../tooling/lib/tooling/events/track_pipeline_events'

RSpec.describe Tooling::Events::TrackPipelineEvents, feature_category: :tooling do
  include StubENV
  let(:event_name) { "e2e_tests_selected_for_execution_gitlab_pipeline" }
  let(:additional_properties) { { label: 'label', property: 'property', value: 10 } }
  let(:access_token) { 'test-admin-token' }
  let(:response) { instance_double(Net::HTTPResponse, code: 200, body: '{}') }
  let(:http_client) { instance_double(Net::HTTP) }
  let(:http_request) { instance_double(Net::HTTP::Post) }

  before do
    stub_env("CI_INTERNAL_EVENTS_TOKEN", access_token)
    stub_env("CI_API_V4_URL", 'https://gitlab.com/api/v4')
    allow($stdout).to receive(:puts)
  end

  describe '#send_event' do
    subject(:send_event) do
      described_class
      .new(event_name: event_name, properties: additional_properties).send_event
    end

    context 'with API request' do
      let(:expected_request_body) do
        {
          event: event_name,
          send_to_snowplow: true,
          namespace_id: Tooling::Events::TrackPipelineEvents::NAMESPACE_ID,
          project_id: Tooling::Events::TrackPipelineEvents::PROJECT_ID,
          additional_properties: additional_properties
        }
      end

      let(:uri_double) do
        instance_double(URI::HTTPS,
          host: 'gitlab.com',
          port: 443, path: 'api/v4/usage_data/track_event')
      end

      before do
        allow(URI).to receive(:parse).and_return(uri_double)
        allow(Net::HTTP).to receive(:new).and_return(http_client)
        allow(http_client).to receive(:use_ssl=).and_return(true)
        allow(Net::HTTP::Post).to receive(:new).with(uri_double.path).and_return(http_request)
        allow(http_request).to receive(:body=)
        allow(http_request).to receive(:[]=)
      end

      context 'when successful' do
        before do
          allow(http_client).to receive(:request).and_return(response)
        end

        it 'sends correct event parameters and success message' do
          send_event
          expect(http_request).to have_received(:body=).with(expected_request_body.to_json)
          expect($stdout).to have_received(:puts).with("Successfully sent data for event: #{event_name}")
        end
      end

      context 'when error response' do
        let(:error_response) do
          instance_double(Net::HTTPResponse, code: 422,
            body: '{"error":"Invalid parameters"}')
        end

        before do
          allow(http_client).to receive(:request).and_return(error_response)
        end

        it 'checks for failed error message' do
          result = send_event
          expect($stdout).to have_received(:puts)
                               .with("Failed event tracking: 422, body: {\"error\":\"Invalid parameters\"}")
          expect(result).to eq(error_response)
        end
      end

      context 'when CI_INTERNAL_EVENTS_TOKEN is not set' do
        before do
          stub_env("CI_INTERNAL_EVENTS_TOKEN", nil)
          allow(http_client).to receive(:request).and_return(response)
        end

        it 'prints an error message and returns' do
          send_event
          expect($stdout).to have_received(:puts)
                               .with("ERROR: Cannot send event '#{event_name}'. Missing project access token.")
        end
      end
    end
  end
end
