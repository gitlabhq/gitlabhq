# coding: utf-8
require 'spec_helper'

describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://container-registry", options) }

  shared_examples '#repository_manifest' do |manifest_type|
    let(:manifest) do
      {
        "schemaVersion" => 2,
        "config" => {
          "mediaType" => manifest_type,
          "digest" =>
          "sha256:4a3ef0786dd241be6000311e1503869b320be433b9cba84cfafeb512d1720c95",
          "size" => 6608
        },
        "layers" => [
          {
            "mediaType" => manifest_type,
            "digest" =>
            "sha256:83ef92b73cf4595aa7fe214ec6747228283d585f373d8f6bc08d66bebab531b7",
            "size" => 2828661
          }
        ]
 }
    end

    it 'GET /v2/:name/manifests/mytag' do
      stub_request(:get, "http://container-registry/v2/group/test/manifests/mytag")
        .with(headers: {
                'Accept' => described_class::ACCEPTED_TYPES.join(', '),
                'Authorization' => "bearer #{token}"
              })
        .to_return(status: 200, body: manifest.to_json, headers: { content_type: manifest_type })

      expect(client.repository_manifest('group/test', 'mytag')).to eq(manifest)
    end
  end

  it_behaves_like '#repository_manifest', described_class::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
  it_behaves_like '#repository_manifest', described_class::OCI_MANIFEST_V1_TYPE

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
