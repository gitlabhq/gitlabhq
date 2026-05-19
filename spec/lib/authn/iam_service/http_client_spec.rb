# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::HttpClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:expected_headers) do
    {
      'Content-Type' => 'application/json',
      Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret
    }
  end

  before do
    allow(Authn::IamAuthService).to receive_messages(
      url: iam_service_url,
      secret: iam_secret
    )
  end

  describe '#put' do
    let(:path) { '/test/resource' }
    let(:query_params) { { token: 'abc' } }
    let(:body) { { key: 'value' } }
    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: '{}')
    end

    before do
      allow(Gitlab::HTTP).to receive(:put).and_return(http_response)
    end

    it 'sends a PUT request with correct URL, body, headers and timeout' do
      client.put(path: path, query_params: query_params, body: body)

      expect(Gitlab::HTTP).to have_received(:put).with(
        "#{iam_service_url}#{path}?token=abc",
        body: body.to_json,
        headers: expected_headers,
        timeout: described_class::TIMEOUT_SECONDS
      )
    end

    context 'when query_params is empty' do
      it 'builds URL without query string' do
        client.put(path: path, query_params: {}, body: body)

        expect(Gitlab::HTTP).to have_received(:put).with(
          "#{iam_service_url}#{path}",
          hash_including(body: body.to_json)
        )
      end
    end
  end

  describe '#get' do
    let(:path) { '/test/resource' }
    let(:query_params) { { token: 'def' } }
    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: '{}')
    end

    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(http_response)
    end

    it 'sends a GET request with correct URL, headers and timeout' do
      client.get(path: path, query_params: query_params)

      expect(Gitlab::HTTP).to have_received(:get).with(
        "#{iam_service_url}#{path}?token=def",
        headers: expected_headers,
        timeout: described_class::TIMEOUT_SECONDS
      )
    end
  end

  describe 'error handling' do
    let(:path) { '/test' }

    context 'when IAM service is not configured' do
      before do
        allow(Authn::IamAuthService).to receive(:url)
          .and_raise(Authn::IamAuthService::ConfigurationError, 'IAM service is not configured')
      end

      it 'raises RequestError with the configuration error message' do
        expect { client.get(path: path) }
          .to raise_error(described_class::RequestError, 'IAM service is not configured')
      end
    end

    context 'when a network error occurs' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
      end

      it 'raises RequestError and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                           .with(instance_of(Errno::ECONNREFUSED))

        expect { client.get(path: path) }
          .to raise_error(described_class::RequestError, 'Failed to connect to IAM service')
      end
    end

    context 'when a timeout occurs' do
      before do
        allow(Gitlab::HTTP).to receive(:put).and_raise(Net::OpenTimeout)
      end

      it 'raises RequestError and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                           .with(instance_of(Net::OpenTimeout))

        expect { client.put(path: path, body: {}) }
          .to raise_error(described_class::RequestError, 'Failed to connect to IAM service')
      end
    end

    context 'when JSON::ParserError is raised' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(JSON::ParserError)
      end

      it 'does not catch it (propagates to caller)' do
        expect { client.get(path: path) }.to raise_error(JSON::ParserError)
      end
    end
  end
end
