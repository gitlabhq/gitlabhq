# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MimirClient do
  include PrometheusHelpers

  subject(:client) { described_class.new(mimir_url: mimir_url, user: 'user', password: 'pass') }

  let(:headers) { { Authorization: 'Basic dXNlcjpwYXNz' } }
  let(:mimir_url) { 'https://mimir.example.com' }
  let(:api_url) { "#{mimir_url}/#{described_class::PROMETHEUS_API_ENDPOINT}" }

  describe '#initialize' do
    let(:query) { { query: 1 }.to_query }
    let(:query_url) { "#{api_url}/api/v1/query?#{query}" }

    it 'forwards the auth headers through HTTP request' do
      request = stub_prometheus_request(
        query_url,
        body: prometheus_value_body('vector'),
        headers: headers
      )

      expect(client.ping).to(
        eq(
          {
            "resultType" => "vector",
            "result" => [
              {
                "metric" => {},
                "value" => [1488772511.004, "0.000041021495238095323"]
              }
            ]
          }
        )
      )
      expect(request).to have_been_requested
    end
  end

  describe '#healthy?' do
    let(:query) { { query: "vector(0)" }.to_query }
    let(:health_url) { "#{api_url}/api/v1/query?#{query}" }

    it 'returns true when status code is 200 and healthy response body' do
      stub_prometheus_request(health_url, body: "", headers: headers)

      expect(client.healthy?).to eq(true)
    end

    it 'returns false when status code is not 200' do
      [401, 403, 503, 500].each do |code|
        stub_prometheus_request(health_url, status: code, body: "", headers: headers)

        expect(client.healthy?).to eq(false)
      end
    end

    it 'raises error when ready api throws exception' do
      stub_request(:get, health_url).with(headers: headers).to_raise(Net::OpenTimeout)

      expect { client.healthy? }.to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError)
    end
  end

  describe '#ready?' do
    let(:ready_url) { "#{mimir_url}/ready" }

    it 'returns true when status code is 200' do
      stub_prometheus_request(ready_url, body: "", headers: headers)

      expect(client.ready?).to eq(true)
    end

    it 'returns false when status code is not 200' do
      [401, 403, 503, 500].each do |code|
        stub_prometheus_request(ready_url, status: code, body: "", headers: headers)

        expect(client.ready?).to eq(false)
      end
    end

    it 'raises error when ready api throws exception' do
      stub_request(:get, ready_url).with(headers: headers).to_raise(Net::OpenTimeout)

      expect { client.ready? }.to raise_error(Gitlab::PrometheusClient::UnexpectedResponseError)
    end
  end
end
