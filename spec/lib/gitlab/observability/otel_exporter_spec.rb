# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability::OtelExporter, feature_category: :integrations do
  let(:base_url) { 'https://observe.gitlab.com' }
  let(:headers) { { 'Authorization' => 'Bearer test-token' } }
  let(:integration) { create_integration(base_url) }
  let(:exporter) { described_class.new(integration) }
  let(:success_response) { instance_double(HTTParty::Response, code: 200, body: 'OK') }

  def create_integration(endpoint_url, integration_headers: headers)
    Struct.new(:otel_endpoint_url, :otel_headers).new(endpoint_url, integration_headers)
  end

  def expect_export_request(endpoint, payload, response: success_response)
    expect(Gitlab::HTTP).to receive(:post).with(
      endpoint,
      hash_including(
        headers: hash_including(
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Authorization' => 'Bearer test-token'
        ),
        body: Gitlab::Json.dump(payload),
        timeout: 30.seconds,
        allow_local_requests: anything
      )
    ).and_return(response)
  end

  shared_examples 'export method' do |method_name, data_key, endpoint_path|
    let(:data) { { data_key => [{ test: 'data' }] } }
    let(:expected_payload) { { data_key => [{ test: 'data' }] } }

    it "sends #{data_key} data to OTEL endpoint" do
      expect_export_request("#{base_url}#{endpoint_path}", expected_payload)

      exporter.public_send(method_name, data)
    end

    context 'when endpoint_url is blank' do
      it 'does not send data' do
        blank_exporter = described_class.new(create_integration(nil))

        expect(Gitlab::HTTP).not_to receive(:post)
        blank_exporter.public_send(method_name, data)
      end
    end

    context 'with authentication errors' do
      it 'raises AuthenticationError for 401' do
        allow(Gitlab::HTTP).to receive(:post).and_return(
          instance_double(HTTParty::Response, code: 401, body: 'Unauthorized')
        )

        expect { exporter.public_send(method_name, data) }.to raise_error(
          Gitlab::Observability::OtelExporter::AuthenticationError,
          'Authentication failed for OTEL endpoint (HTTP 401)'
        )
      end

      it 'raises AuthenticationError for 403' do
        allow(Gitlab::HTTP).to receive(:post).and_return(
          instance_double(HTTParty::Response, code: 403, body: 'Forbidden')
        )

        expect { exporter.public_send(method_name, data) }.to raise_error(
          Gitlab::Observability::OtelExporter::AuthenticationError,
          'Authentication failed for OTEL endpoint (HTTP 403)'
        )
      end
    end

    it 'handles rate limiting gracefully' do
      allow(Gitlab::HTTP).to receive(:post).and_return(
        instance_double(HTTParty::Response, code: 429, body: 'Too Many Requests')
      )

      expect { exporter.public_send(method_name, data) }.not_to raise_error
    end

    it 'handles other errors' do
      allow(Gitlab::HTTP).to receive(:post).and_return(
        instance_double(HTTParty::Response, code: 500, body: 'Internal Server Error')
      )

      expect { exporter.public_send(method_name, data) }.to raise_error(
        Gitlab::Observability::OtelExporter::ExportError,
        'OTEL endpoint returned error 500'
      )
    end

    it 'handles network errors' do
      allow(Gitlab::HTTP).to receive(:post).and_raise(SocketError, 'Network error')

      type_name = method_name.to_s.gsub('export_', '')
      expect { exporter.public_send(method_name, data) }.to raise_error(
        Gitlab::Observability::OtelExporter::NetworkError,
        "Failed to export #{type_name} to OTEL endpoint: Network error"
      )
    end

    context 'with empty data' do
      it 'handles empty hash gracefully' do
        expect(Gitlab::HTTP).not_to receive(:post)
        exporter.public_send(method_name, {})
      end

      it 'handles nil gracefully' do
        expect(Gitlab::HTTP).not_to receive(:post)
        exporter.public_send(method_name, nil)
      end
    end
  end

  describe '#export_traces' do
    it_behaves_like 'export method', :export_traces, :resourceSpans, '/v1/traces'
  end

  describe '#export_metrics' do
    it_behaves_like 'export method', :export_metrics, :resourceMetrics, '/v1/metrics'
  end

  describe '#export_logs' do
    it_behaves_like 'export method', :export_logs, :resourceLogs, '/v1/logs'
  end

  describe 'endpoint configuration' do
    before do
      allow(Gitlab::HTTP).to receive(:post).and_return(success_response)
    end

    it 'uses correct endpoint for GitLab Observability' do
      exporter.export_traces({ resourceSpans: [] })

      expect(Gitlab::HTTP).to have_received(:post).with(
        "#{base_url}/v1/traces",
        anything
      )
    end

    it 'handles endpoint_url with trailing slash' do
      trailing_slash_exporter = described_class.new(create_integration("#{base_url}/"))
      trailing_slash_exporter.export_traces({ resourceSpans: [] })

      expect(Gitlab::HTTP).to have_received(:post).with(
        "#{base_url}/v1/traces",
        anything
      )
    end
  end

  describe '#initialize' do
    context 'when integration does not respond to required methods' do
      %w[otel_endpoint_url otel_headers both_methods].each do |missing_method|
        it "raises ArgumentError when integration does not respond to #{missing_method}" do
          invalid_integration = case missing_method
                                when 'otel_endpoint_url'
                                  Struct.new(:otel_headers).new(headers)
                                when 'otel_headers'
                                  Struct.new(:otel_endpoint_url).new(base_url)
                                when 'both_methods'
                                  Object.new
                                end

          expect { described_class.new(invalid_integration) }.to raise_error(
            ArgumentError,
            'Integration must respond to otel_endpoint_url and otel_headers'
          )
        end
      end
    end
  end

  describe '#export_data' do
    context 'when unknown export type is provided' do
      [
        [:unknown_type, 'unknown_type'],
        %w[invalid invalid],
        [123, '123']
      ].each do |type, expected_message|
        it "raises ArgumentError for #{type.inspect}" do
          expect { exporter.send(:export_data, type, { some: 'data' }) }.to raise_error(
            ArgumentError,
            "Unknown export type: #{expected_message}"
          )
        end
      end
    end
  end
end
