# frozen_string_literal: true

require 'gitlab/rspec/stub_env'
require 'logger'

require_relative '../../../../../tooling/lib/tooling/events/track_pipeline_events'

RSpec.describe Tooling::Events::TrackPipelineEvents, feature_category: :tooling do
  include StubENV

  subject(:send_event) { described_class.new(logger: logger).send_event(event_name, **additional_properties) }

  let(:event_name) { "e2e_tests_selected_for_execution_gitlab_pipeline" }
  let(:additional_properties) { { label: 'label', value: 10, property: 'property' } }
  let(:access_token) { 'test-admin-token' }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:http_client) { instance_double(Net::HTTP, :use_ssl= => true, :request_post => response) }
  let(:response) { instance_double(Net::HTTPResponse, code: 200, body: '{}') }
  let(:api_path) { "/api/v4/usage_data/track_event" }
  let(:headers) do
    {
      "PRIVATE-TOKEN" => access_token,
      "Content-Type" => "application/json"
    }
  end

  before do
    stub_env("CI_INTERNAL_EVENTS_TOKEN", access_token)
    stub_env("CI_SERVER_URL", "https://gitlab.com")
    stub_env("CI_PROJECT_NAMESPACE_ID", "1")
    stub_env("CI_PROJECT_ID", "2")
  end

  describe '#send_event' do
    context 'with API request' do
      before do
        allow(Net::HTTP).to receive(:new).and_return(http_client)
      end

      it "sets up correct http client" do
        send_event

        expect(Net::HTTP).to have_received(:new).with('gitlab.com', 443)
        expect(http_client).to have_received(:use_ssl=).with(true)
      end

      context 'when successful' do
        let(:expected_request_body) do
          {
            event: event_name,
            send_to_snowplow: true,
            namespace_id: 1,
            project_id: 2,
            additional_properties: additional_properties
          }.to_json
        end

        it 'sends correct event parameters and success message' do
          send_event

          expect(http_client).to have_received(:request_post).with(api_path, expected_request_body, headers)
          expect(logger).to have_received(:info).with(
            "Successfully sent data with properties: #{additional_properties}"
          )
        end
      end

      context 'when error response' do
        let(:response) do
          instance_double(Net::HTTPResponse, code: 422, body: '{"error":"Invalid parameters"}')
        end

        it 'checks for failed error message' do
          expect(send_event).to eq(response)
          expect(logger).to have_received(:error).with("Failed event tracking: 422, body: #{response.body}")
        end
      end

      context 'when error is raised' do
        before do
          allow(http_client).to receive(:request_post).and_raise(StandardError, "some error")
        end

        it 'logs the error' do
          send_event

          expect(logger).to have_received(:error).with(
            "Exception when posting event #{event_name}, error: 'some error'"
          )
        end
      end

      context 'without logger configured' do
        let(:logger) { nil }

        it 'logs to stdout' do
          expect { send_event }.to output(/Successfully sent data with properties:/).to_stdout
        end
      end

      context 'when CI_INTERNAL_EVENTS_TOKEN is not set' do
        before do
          stub_env("CI_INTERNAL_EVENTS_TOKEN", nil)
        end

        it 'prints an error message and returns' do
          send_event

          expect(logger).to have_received(:error)
            .with("Error: Cannot send event '#{event_name}'. Missing project access token.")
        end
      end
    end
  end
end
