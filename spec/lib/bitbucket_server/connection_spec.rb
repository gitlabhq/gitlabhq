# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Connection, feature_category: :importers do
  let(:options) { { base_uri: 'https://test:7990', user: 'bitbucket', password: 'mypassword' } }
  let(:payload) { { 'test' => 1 } }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:url) { 'https://test:7990/rest/api/1.0/test?something=1' }

  subject { described_class.new(options) }

  describe '#get' do
    before do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' })
        .to_return(body: payload.to_json, status: 200, headers: headers)
    end

    it 'runs with retry_with_delay' do
      expect(subject).to receive(:retry_with_delay).and_call_original.once

      subject.get(url)
    end

    it 'returns JSON body' do
      expect(subject.get(url, { something: 1 })).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' }).to_return(body: payload.to_json, status: 500, headers: headers)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    it 'includes the HTTP status code in the ConnectionError' do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' })
        .to_return(body: { 'errors' => [{ 'message' => 'Not Found' }] }.to_json, status: 404, headers: headers)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError) do |error|
        expect(error.http_status_code).to eq(404)
      end
    end

    it 'sets http_status_code to nil for non-HTTP errors' do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' }).to_raise(OpenSSL::SSL::SSLError)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError) do |error|
        expect(error.http_status_code).to be_nil
      end
    end
  end

  describe 'ConnectionError#retryable?' do
    using RSpec::Parameterized::TableSyntax

    where(:status_code, :expected_retryable) do
      nil | true
      401 | false
      403 | false
      404 | false
      410 | false
      408 | true
      429 | true
      500 | true
      502 | true
      503 | true
      599 | true
      600 | false
    end

    with_them do
      it 'returns the expected value' do
        error = described_class::ConnectionError.new('test', http_status_code: status_code)
        expect(error.retryable?).to eq(expected_retryable)
      end
    end

    it 'throws an exception if the response is not JSON' do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' }).to_return(body: 'bad data', status: 200, headers: headers)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    it 'raises JSON::NestingError as is' do
      response = instance_double(HTTParty::Response, code: 200)

      allow(response).to receive(:parsed_response).and_raise(JSON::NestingError)
      allow(Import::Clients::HTTP).to receive(:get).and_return(response)

      expect { subject.get(url, { something: 1 }) }.to raise_error(JSON::NestingError)
    end

    it 'throws an exception upon a network error' do
      WebMock.stub_request(:get, url).with(headers: { 'Accept' => 'application/json' }).to_raise(OpenSSL::SSL::SSLError)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end

    context 'when the response is a 429 rate limit reached error' do
      let(:response) do
        instance_double(HTTParty::Response, parsed_response: payload, code: 429, headers: headers.merge('retry-after' => '0'))
      end

      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(response)
      end

      it 'sleeps, retries and if the error persists it fails' do
        expect(Gitlab::BitbucketServerImport::Logger).to receive(:info)
          .with(message: 'Retrying in 0 seconds due to 429 Too Many Requests')
          .once

        expect { subject.get(url) }.to raise_error(BitbucketServer::Connection::ConnectionError)
      end
    end
  end

  describe '#post' do
    let(:headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

    before do
      WebMock.stub_request(:post, url).with(headers: headers).to_return(body: payload.to_json, status: 200, headers: headers)
    end

    it 'runs with retry_with_delay' do
      expect(subject).to receive(:retry_with_delay).and_call_original.once

      subject.post(url, payload)
    end

    it 'returns JSON body' do
      expect(subject.post(url, payload)).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      WebMock.stub_request(:post, url).with(headers: headers).to_return(body: payload.to_json, status: 500, headers: headers)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end

    it 'throws an exception upon a network error' do
      WebMock.stub_request(:post, url).with(headers: { 'Accept' => 'application/json' }).to_raise(OpenSSL::SSL::SSLError)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end

    it 'throws an exception if the URI is invalid' do
      stub_request(:post, url).with(headers: { 'Accept' => 'application/json' }).to_raise(URI::InvalidURIError)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end
  end

  describe '#delete' do
    let(:headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

    before do
      WebMock.stub_request(:delete, branch_url).with(headers: headers).to_return(body: payload.to_json, status: 200, headers: headers)
    end

    context 'branch API' do
      let(:branch_path) { '/projects/foo/repos/bar/branches' }
      let(:branch_url) { 'https://test:7990/rest/branch-utils/1.0/projects/foo/repos/bar/branches' }
      let(:path) {}

      it 'runs with retry_with_delay' do
        expect(subject).to receive(:retry_with_delay).and_call_original.once

        subject.delete(:branches, branch_path, payload)
      end

      it 'returns JSON body' do
        expect(subject.delete(:branches, branch_path, payload)).to eq(payload)
      end

      it 'throws an exception if the response is not 200' do
        WebMock.stub_request(:delete, branch_url).with(headers: headers).to_return(body: payload.to_json, status: 500, headers: headers)

        expect { subject.delete(:branches, branch_path, payload) }.to raise_error(described_class::ConnectionError)
      end

      it 'throws an exception upon a network error' do
        WebMock.stub_request(:delete, branch_url).with(headers: headers).to_raise(OpenSSL::SSL::SSLError)

        expect { subject.delete(:branches, branch_path, payload) }.to raise_error(described_class::ConnectionError)
      end
    end
  end
end
