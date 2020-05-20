# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::Client do
  let(:token) { '12345' }
  let(:options) { { token: token } }
  let(:client) { described_class.new("http://container-registry", options) }
  let(:push_blob_headers) do
    {
        'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
        'Authorization' => "bearer #{token}",
        'Content-Type' => 'application/octet-stream',
        'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end
  let(:headers_with_accept_types) do
    {
      'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
      'Authorization' => "bearer #{token}",
      'User-Agent' => "GitLab/#{Gitlab::VERSION}"
    }
  end

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
                'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
                'Authorization' => "bearer #{token}",
                'User-Agent' => "GitLab/#{Gitlab::VERSION}"
              })
        .to_return(status: 200, body: manifest.to_json, headers: { content_type: manifest_type })

      expect(client.repository_manifest('group/test', 'mytag')).to eq(manifest)
    end
  end

  it_behaves_like '#repository_manifest', described_class::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
  it_behaves_like '#repository_manifest', described_class::OCI_MANIFEST_V1_TYPE

  describe '#blob' do
    let(:blob_headers) do
      {
          'Accept' => 'application/octet-stream',
          'Authorization' => "bearer #{token}",
          'User-Agent' => "GitLab/#{Gitlab::VERSION}"
      }
    end

    let(:redirect_header) do
      {
        'User-Agent' => "GitLab/#{Gitlab::VERSION}"
      }
    end

    it 'GET /v2/:name/blobs/:digest' do
      stub_request(:get, "http://container-registry/v2/group/test/blobs/sha256:0123456789012345")
        .with(headers: blob_headers)
        .to_return(status: 200, body: "Blob")

      expect(client.blob('group/test', 'sha256:0123456789012345')).to eq('Blob')
    end

    it 'follows 307 redirect for GET /v2/:name/blobs/:digest' do
      stub_request(:get, "http://container-registry/v2/group/test/blobs/sha256:0123456789012345")
        .with(headers: blob_headers)
        .to_return(status: 307, body: '', headers: { Location: 'http://redirected' })
      # We should probably use hash_excluding here, but that requires an update to WebMock:
      # https://github.com/bblimke/webmock/blob/master/lib/webmock/matchers/hash_excluding_matcher.rb
      stub_request(:get, "http://redirected/")
        .with(headers: redirect_header) do |request|
          !request.headers.include?('Authorization')
        end
        .to_return(status: 200, body: "Successfully redirected")

      response = client.blob('group/test', 'sha256:0123456789012345')

      expect(response).to eq('Successfully redirected')
    end
  end

  def stub_upload(path, content, digest, status = 200)
    stub_request(:post, "http://container-registry/v2/#{path}/blobs/uploads/")
      .with(headers: headers_with_accept_types)
      .to_return(status: status, body: "", headers: { 'location' => 'http://container-registry/next_upload?id=someid' })

    stub_request(:put, "http://container-registry/next_upload?digest=#{digest}&id=someid")
      .with(body: content, headers: push_blob_headers)
      .to_return(status: status, body: "", headers: {})
  end

  describe '#upload_blob' do
    subject { client.upload_blob('path', 'content', 'sha256:123') }

    context 'with successful uploads' do
      it 'starts the upload and posts the blob' do
        stub_upload('path', 'content', 'sha256:123')

        expect(subject).to be_success
      end
    end

    context 'with a failed upload' do
      before do
        stub_upload('path', 'content', 'sha256:123', 400)
      end

      it 'returns a failure' do
        expect(subject).not_to be_success
      end
    end
  end

  describe '#generate_empty_manifest' do
    subject { client.generate_empty_manifest('path') }

    let(:result_manifest) do
      {
        schemaVersion: 2,
        mediaType: 'application/vnd.docker.distribution.manifest.v2+json',
        config: {
          mediaType: 'application/vnd.docker.container.image.v1+json',
          size: 21,
          digest: 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3'
        }
      }
    end

    it 'uploads a random image and returns the manifest' do
      stub_upload('path', "{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

      expect(subject).to eq(result_manifest)
    end

    context 'when upload fails' do
      before do
        stub_upload('path', "{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3', 500)
      end

      it { is_expected.to be nil }
    end
  end

  describe '#put_tag' do
    let(:manifest_headers) do
      {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => "bearer #{token}",
          'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json',
          'User-Agent' => "GitLab/#{Gitlab::VERSION}"
      }
    end

    subject { client.put_tag('path', 'tagA', { foo: :bar }) }

    it 'uploads the manifest and returns the digest' do
      stub_request(:put, "http://container-registry/v2/path/manifests/tagA")
        .with(body: "{\n  \"foo\": \"bar\"\n}", headers: manifest_headers)
        .to_return(status: 200, body: "", headers: { 'docker-content-digest' => 'sha256:123' })

      expect(subject).to eq 'sha256:123'
    end
  end

  describe '#delete_repository_tag_by_name' do
    subject { client.delete_repository_tag_by_name('group/test', 'a') }

    context 'when the tag exists' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/tags/reference/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 200, body: "")
      end

      it { is_expected.to be_truthy }
    end

    context 'when the tag does not exist' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/tags/reference/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 404, body: "")
      end

      it { is_expected.to be_truthy }
    end

    context 'when an error occurs' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/tags/reference/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 500, body: "")
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#supports_tag_delete?' do
    subject { client.supports_tag_delete? }

    context 'when the server supports tag deletion' do
      before do
        stub_request(:options, "http://container-registry/v2/name/tags/reference/tag")
          .to_return(status: 200, body: "", headers: { 'Allow' => 'DELETE' })
      end

      it { is_expected.to be_truthy }
    end

    context 'when the server does not support tag deletion' do
      before do
        stub_request(:options, "http://container-registry/v2/name/tags/reference/tag")
          .to_return(status: 404, body: "")
      end

      it { is_expected.to be_falsey }
    end
  end

  def stub_registry_info(headers: {}, status: 200)
    stub_request(:get, 'http://container-registry/v2/')
      .to_return(status: status, body: "", headers: headers)
  end

  describe '#registry_info' do
    subject { client.registry_info }

    context 'when the check is successful' do
      context 'when using the GitLab container registry' do
        before do
          stub_registry_info(headers: {
            'GitLab-Container-Registry-Version' => '2.9.1-gitlab',
            'GitLab-Container-Registry-Features' => 'a,b,c'
          })
        end

        it 'identifies the vendor as "gitlab"' do
          expect(subject).to include(vendor: 'gitlab')
        end

        it 'identifies version and features' do
          expect(subject).to include(version: '2.9.1-gitlab', features: %w[a b c])
        end
      end

      context 'when using a third-party container registry' do
        before do
          stub_registry_info
        end

        it 'identifies the vendor as "other"' do
          expect(subject).to include(vendor: 'other')
        end

        it 'does not identify version or features' do
          expect(subject).to include(version: nil, features: [])
        end
      end
    end

    context 'when the check is not successful' do
      it 'does not identify vendor, version or features' do
        stub_registry_info(status: 500)

        expect(subject).to eq({})
      end
    end
  end
end
