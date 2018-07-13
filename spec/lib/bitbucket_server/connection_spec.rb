require 'spec_helper'

describe BitbucketServer::Connection do
  let(:options) { { base_uri: 'https://test:7990', user: 'bitbucket', password: 'mypassword' } }
  let(:payload) { { 'test' => 1 } }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:url) { 'https://test:7990/rest/api/1.0/test?something=1' }

  subject { described_class.new(options) }

  describe '#get' do
    it 'returns JSON body' do
      WebMock.stub_request(:get, url).to_return(body: payload.to_json, status: 200, headers: headers)

      expect(subject.get(url, { something: 1 })).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      WebMock.stub_request(:get, url).to_return(body: payload.to_json, status: 500, headers: headers)

      expect { subject.get(url) }.to raise_error(described_class::ConnectionError)
    end
  end

  describe '#post' do
    it 'returns JSON body' do
      WebMock.stub_request(:post, url).to_return(body: payload.to_json, status: 200, headers: headers)

      expect(subject.post(url, payload)).to eq(payload)
    end

    it 'throws an exception if the response is not 200' do
      WebMock.stub_request(:post, url).to_return(body: payload.to_json, status: 500, headers: headers)

      expect { subject.post(url, payload) }.to raise_error(described_class::ConnectionError)
    end
  end
end
