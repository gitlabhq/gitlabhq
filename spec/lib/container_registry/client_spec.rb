# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Client, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  include_context 'container registry client'

  shared_examples 'handling timeouts' do
    let(:retry_options) do
      ContainerRegistry::Client::RETRY_OPTIONS.merge(
        interval: 0.1,
        interval_randomness: 0,
        backoff_factor: 0
      )
    end

    before do
      stub_request(method, url).to_timeout
    end

    it 'handles network timeouts' do
      actual_retries = 0
      retry_options_with_block = retry_options.merge(
        retry_block: ->(*) { actual_retries += 1 }
      )

      stub_const('ContainerRegistry::BaseClient::RETRY_OPTIONS', retry_options_with_block)

      expect { subject }.to raise_error(Faraday::ConnectionFailed)
      expect(actual_retries).to eq(retry_options_with_block[:max])
    end

    it 'logs the error' do
      stub_const('ContainerRegistry::BaseClient::RETRY_OPTIONS', retry_options)

      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .exactly(retry_options[:max] + 1)
        .times
        .with(
          an_instance_of(Faraday::ConnectionFailed),
          class: ::ContainerRegistry::BaseClient.name,
          url: URI(url)
        )

      expect { subject }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  shared_examples 'handling repository manifest' do |manifest_type|
    let(:method) { :get }
    let(:url) {  'http://container-registry/v2/group/test/manifests/mytag' }
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
      stub_request(method, url)
        .with(headers: {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => "bearer #{token}",
          'User-Agent' => "GitLab/#{Gitlab::VERSION}"
        })
        .to_return(status: 200, body: manifest.to_json, headers: { content_type: manifest_type })

      expect_new_faraday

      expect(subject).to eq(manifest)
    end

    it_behaves_like 'handling timeouts'
  end

  shared_examples 'handling registry info' do
    context 'when the check is successful' do
      context 'when using the GitLab container registry' do
        before do
          stub_registry_info(headers: {
            'GitLab-Container-Registry-Version' => '2.9.1-gitlab',
            'GitLab-Container-Registry-Features' => 'a,b,c',
            'GitLab-Container-Registry-Database-Enabled' => 'true'
          })
        end

        it 'identifies the vendor as "gitlab"' do
          expect(subject).to include(vendor: 'gitlab')
        end

        it 'identifies version and features' do
          expect(subject).to include(version: '2.9.1-gitlab', features: %w[a b c])
        end

        it 'identifies the registry DB as enabled' do
          expect(subject).to include(db_enabled: true)
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

        it 'does not identify the registry DB as enabled' do
          expect(subject).to include(db_enabled: false)
        end
      end
    end

    context 'when the check is not successful' do
      it 'does not identify vendor, version or features' do
        stub_registry_info(status: 500)

        expect(subject).to eq({})
      end
    end

    context 'when the check returns an unexpected value in the database enabled header' do
      it 'does not identify the registry DB as enabled' do
        stub_registry_info(headers: {
          'GitLab-Container-Registry-Database-Enabled' => '123'
        })

        expect(subject).to include(db_enabled: false)
      end
    end
  end

  describe '#repository_manifest' do
    subject { client.repository_manifest('group/test', 'mytag') }

    it_behaves_like 'handling repository manifest', described_class::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
    it_behaves_like 'handling repository manifest', described_class::OCI_MANIFEST_V1_TYPE
  end

  describe '#blob' do
    let(:method) { :get }
    let(:url) { 'http://container-registry/v2/group/test/blobs/sha256:0123456789012345' }
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

    subject { client.blob('group/test', 'sha256:0123456789012345') }

    it 'GET /v2/:name/blobs/:digest' do
      stub_request(method, url)
        .with(headers: blob_headers)
        .to_return(status: 200, body: "Blob")

      expect_new_faraday

      expect(subject).to eq('Blob')
    end

    context 'with a 307 redirect' do
      let(:redirect_location) { 'http://redirected' }

      before do
        stub_request(method, url)
          .with(headers: blob_headers)
          .to_return(status: 307, body: '', headers: { Location: redirect_location })

        # We should probably use hash_excluding here, but that requires an update to WebMock:
        # https://github.com/bblimke/webmock/blob/master/lib/webmock/matchers/hash_excluding_matcher.rb
        stub_request(:get, redirect_location)
          .with(headers: redirect_header) do |request|
            request.headers.exclude?('Authorization')
          end
          .to_return(status: 200, body: "Successfully redirected")
      end

      shared_examples 'handling redirects' do
        it 'follows the redirect' do
          expect(Faraday::Utils).not_to receive(:escape).with('signature=')
          expect_new_faraday
          expect(subject).to eq('Successfully redirected')
        end
      end

      it_behaves_like 'handling redirects'

      context 'with a redirect location with params ending with =' do
        let(:redirect_location) { 'http://redirect?foo=bar&test=signature=' }

        it_behaves_like 'handling redirects'
      end

      context 'with a redirect location with params ending with %3D' do
        let(:redirect_location) { 'http://redirect?foo=bar&test=signature%3D' }

        it_behaves_like 'handling redirects'
      end
    end

    it_behaves_like 'handling timeouts'
  end

  describe '#upload_blob' do
    subject { client.upload_blob('path', 'content', 'sha256:123') }

    context 'with successful uploads' do
      it 'starts the upload and posts the blob' do
        stub_upload('path', 'content', 'sha256:123')

        expect_new_faraday(timeout: false)

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
        .to_return(status: 200, body: "", headers: { DependencyProxy::Manifest::DIGEST_HEADER => 'sha256:123' })

      expect_new_faraday(timeout: false)

      expect(subject).to eq 'sha256:123'
    end
  end

  describe '#delete_repository_tag_by_digest' do
    subject { client.delete_repository_tag_by_digest('group/test', 'a') }

    context 'when the tag exists' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/manifests/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 200, body: "")
      end

      it { is_expected.to be_truthy }
    end

    context 'when the tag does not exist' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/manifests/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 404, body: "")
      end

      it { is_expected.to be_truthy }
    end

    context 'when an error occurs' do
      before do
        stub_request(:delete, "http://container-registry/v2/group/test/manifests/a")
          .with(headers: headers_with_accept_types)
          .to_return(status: 500, body: "")
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#supports_tag_delete?' do
    subject { client.supports_tag_delete? }

    where(:registry_tags_support_enabled, :is_on_dot_com, :container_registry_features, :expect_registry_to_be_pinged, :expected_result) do
      true  | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | true
      true  | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | true  | true
      true  | true  | []                                             | true  | true
      true  | false | []                                             | true  | true
      false | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | true
      false | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | true  | false
      false | true  | []                                             | true  | false
      false | false | []                                             | true  | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com_except_jh?).and_return(is_on_dot_com)
        stub_registry_tags_support(registry_tags_support_enabled)
        stub_application_setting(container_registry_features: container_registry_features)
      end

      it 'returns the expected result' do
        if expect_registry_to_be_pinged
          expect_next_instance_of(Faraday::Connection) do |connection|
            expect(connection).to receive(:run_request).and_call_original
          end
        else
          expect(Faraday::Connection).not_to receive(:new)
        end

        expect(subject).to be expected_result
      end
    end
  end

  describe '#registry_info' do
    subject { client.registry_info }

    it_behaves_like 'handling registry info'
  end

  describe '.supports_tag_delete?' do
    subject { described_class.supports_tag_delete? }

    where(:registry_api_url, :registry_enabled, :registry_tags_support_enabled, :is_on_dot_com, :container_registry_features, :expect_registry_to_be_pinged, :expected_result) do
      'http://sandbox.local' | true  | true  | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | true
      'http://sandbox.local' | true  | true  | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | true  | true
      'http://sandbox.local' | true  | false | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | true
      'http://sandbox.local' | true  | false | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | true  | false
      'http://sandbox.local' | false | true  | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      'http://sandbox.local' | false | true  | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      'http://sandbox.local' | false | false | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      'http://sandbox.local' | false | false | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      'http://sandbox.local' | true  | true  | true  | []                                             | true  | true
      'http://sandbox.local' | true  | true  | false | []                                             | true  | true
      'http://sandbox.local' | true  | false | true  | []                                             | true  | false
      'http://sandbox.local' | true  | false | false | []                                             | true  | false
      'http://sandbox.local' | false | true  | true  | []                                             | false | false
      'http://sandbox.local' | false | true  | false | []                                             | false | false
      'http://sandbox.local' | false | false | true  | []                                             | false | false
      'http://sandbox.local' | false | false | false | []                                             | false | false
      ''                     | true  | true  | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | true  | true  | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | true  | false | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | true  | false | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | false | true  | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | false | true  | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | false | false | true  | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | false | false | false | [described_class::REGISTRY_TAG_DELETE_FEATURE] | false | false
      ''                     | true  | true  | true  | []                                             | false | false
      ''                     | true  | true  | false | []                                             | false | false
      ''                     | true  | false | true  | []                                             | false | false
      ''                     | true  | false | false | []                                             | false | false
      ''                     | false | true  | true  | []                                             | false | false
      ''                     | false | true  | false | []                                             | false | false
      ''                     | false | false | true  | []                                             | false | false
      ''                     | false | false | false | []                                             | false | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com_except_jh?).and_return(is_on_dot_com)
        stub_container_registry_config(enabled: registry_enabled, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
        stub_registry_tags_support(registry_tags_support_enabled)
        stub_application_setting(container_registry_features: container_registry_features)
      end

      it 'returns the expected result' do
        if expect_registry_to_be_pinged
          expect_next_instance_of(Faraday::Connection) do |connection|
            expect(connection).to receive(:run_request).and_call_original
          end
        else
          expect(Faraday::Connection).not_to receive(:new)
        end

        expect(subject).to be expected_result
      end
    end
  end

  describe '#repository_tags' do
    let(:path) { 'repository/path' }

    subject { client.repository_tags(path) }

    before do
      stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
    end

    it 'returns a successful response' do
      stub_registry_tags_list(query_params: { n: described_class::DEFAULT_TAGS_PAGE_SIZE }, tags: %w[t1 t2])

      expect(subject).to eq('tags' => %w[t1 t2])
    end
  end

  describe '.registry_info' do
    subject { described_class.registry_info }

    before do
      stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
    end

    it_behaves_like 'handling registry info'
  end

  describe '#connected?' do
    subject { client.connected? }

    context 'with a valid connection' do
      before do
        stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
        stub_registry_info
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'with an invalid connection' do
      before do
        stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
        stub_registry_info(status: 500)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  def stub_upload(path, content, digest, status = 200)
    stub_request(:post, "#{registry_api_url}/v2/#{path}/blobs/uploads/")
      .with(headers: headers_with_accept_types)
      .to_return(status: status, body: "", headers: { 'location' => "#{registry_api_url}/next_upload?id=someid" })

    stub_request(:put, "#{registry_api_url}/next_upload?digest=#{digest}&id=someid")
      .with(body: content, headers: push_blob_headers)
      .to_return(status: status, body: "", headers: {})
  end

  def stub_registry_info(headers: {}, status: 200)
    stub_request(:get, "#{registry_api_url}/v2/")
      .to_return(status: status, body: "", headers: headers)
  end

  def stub_registry_tags_support(supported = true)
    status_code = supported ? 200 : 404
    stub_request(:options, "#{registry_api_url}/v2/name/manifests/tag")
      .to_return(
        status: status_code,
        body: '',
        headers: { 'Allow' => 'DELETE' }
      )
  end

  def stub_registry_tags_list(query_params: {}, status: 200, tags: ['test_tag'])
    url = "#{registry_api_url}/v2/#{path}/tags/list"

    unless query_params.empty?
      url += "?"
      url += query_params.map { |k, v| "#{k}=#{v}" }.join(',')
    end

    stub_request(:get, url)
      .with(headers: { 'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') })
      .to_return(
        status: status,
        body: Gitlab::Json.dump(tags: tags),
        headers: { 'Content-Type' => 'application/json' })
  end

  def expect_new_faraday(times: 1, timeout: true)
    request_options = timeout ? expected_faraday_request_options : nil
    expect(Faraday)
      .to receive(:new)
      .with(
        'http://container-registry',
        headers: expected_faraday_headers,
        request: request_options
      ).and_call_original
      .exactly(times)
      .times
  end
end
