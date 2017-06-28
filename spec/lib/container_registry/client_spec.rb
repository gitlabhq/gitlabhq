# coding: utf-8
require 'spec_helper'

describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://container-registry", options) }

  describe '#blob' do
    it 'GET /v2/:name/blobs/:digest' do
      stub_request(:get, "http://container-registry/v2/group/test/blobs/sha256:0123456789012345")
        .with(headers: {
               'Accept' => 'application/octet-stream',
               'Authorization' => "bearer #{token}"
             })
        .to_return(status: 200, body: "Blob")

      expect(client.blob('group/test', 'sha256:0123456789012345')).to eq('Blob')
    end

    it 'follows 307 redirect for GET /v2/:name/blobs/:digest' do
      stub_request(:get, "http://container-registry/v2/group/test/blobs/sha256:0123456789012345")
        .with(headers: {
               'Accept' => 'application/octet-stream',
               'Authorization' => "bearer #{token}"
             })
        .to_return(status: 307, body: "", headers: { Location: 'http://redirected' })
      # We should probably use hash_excluding here, but that requires an update to WebMock:
      # https://github.com/bblimke/webmock/blob/master/lib/webmock/matchers/hash_excluding_matcher.rb
      stub_request(:get, "http://redirected/")
        .with { |request| !request.headers.include?('Authorization') }
        .to_return(status: 200, body: "Successfully redirected")

      response = client.blob('group/test', 'sha256:0123456789012345')

      expect(response).to eq('Successfully redirected')
    end
  end
end
