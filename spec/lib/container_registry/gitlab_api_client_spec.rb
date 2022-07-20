# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::GitlabApiClient do
  using RSpec::Parameterized::TableSyntax

  include_context 'container registry client'
  include_context 'container registry client stubs'

  let(:path) { 'namespace/path/to/repository' }
  let(:import_token) { 'import_token' }
  let(:options) { { token: token, import_token: import_token } }

  describe '#supports_gitlab_api?' do
    subject { client.supports_gitlab_api? }

    where(:registry_gitlab_api_enabled, :is_on_dot_com, :container_registry_features, :expect_registry_to_be_pinged, :expected_result) do
      false | true  | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | false | true
      true  | false | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | true  | true
      true  | true  | []                                                | true  | true
      true  | false | []                                                | true  | true
      false | true  | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | false | true
      false | false | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | true  | false
      false | true  | []                                                | true  | false
      false | false | []                                                | true  | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(is_on_dot_com)
        stub_registry_gitlab_api_support(registry_gitlab_api_enabled)
        stub_application_setting(container_registry_features: container_registry_features)
      end

      it 'returns the expected result' do
        if expect_registry_to_be_pinged
          expect(Faraday::Connection).to receive(:new).and_call_original
        else
          expect(Faraday::Connection).not_to receive(:new)
        end

        expect(subject).to be expected_result
      end
    end

    context 'with 401 response' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        stub_application_setting(container_registry_features: [])
        stub_request(:get, "#{registry_api_url}/gitlab/v1/")
          .to_return(status: 401, body: '')
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#pre_import_repository' do
    subject { client.pre_import_repository(path) }

    where(:status_code, :expected_result) do
      200 | :already_imported
      202 | :ok
      400 | :bad_request
      401 | :unauthorized
      404 | :not_found
      409 | :already_being_imported
      418 | :error
      424 | :pre_import_failed
      425 | :already_being_imported
      429 | :too_many_imports
    end

    with_them do
      before do
        stub_pre_import(path, status_code, pre: true)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#import_repository' do
    subject { client.import_repository(path) }

    where(:status_code, :expected_result) do
      200 | :already_imported
      202 | :ok
      400 | :bad_request
      401 | :unauthorized
      404 | :not_found
      409 | :already_being_imported
      418 | :error
      424 | :pre_import_failed
      425 | :already_being_imported
      429 | :too_many_imports
    end

    with_them do
      before do
        stub_pre_import(path, status_code, pre: false)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#cancel_repository_import' do
    let(:force) { false }

    subject { client.cancel_repository_import(path, force: force) }

    where(:status_code, :expected_result) do
      200 | :already_imported
      202 | :ok
      400 | :bad_request
      401 | :unauthorized
      404 | :not_found
      409 | :already_being_imported
      418 | :error
      424 | :pre_import_failed
      425 | :already_being_imported
      429 | :too_many_imports
    end

    with_them do
      before do
        stub_import_cancel(path, status_code, force: force)
      end

      it { is_expected.to eq({ status: expected_result, migration_state: nil }) }
    end

    context 'bad request' do
      let(:status) { 'this_is_a_test' }

      before do
        stub_import_cancel(path, 400, status: status, force: force)
      end

      it { is_expected.to eq({ status: :bad_request, migration_state: status }) }
    end

    context 'force cancel' do
      let(:force) { true }

      before do
        stub_import_cancel(path, 202, force: force)
      end

      it { is_expected.to eq({ status: :ok, migration_state: nil }) }
    end
  end

  describe '#import_status' do
    subject { client.import_status(path) }

    context 'with successful response' do
      before do
        stub_import_status(path, status)
      end

      context 'with a status' do
        let(:status) { 'this_is_a_test' }

        it { is_expected.to eq(status) }
      end

      context 'with no status' do
        let(:status) { nil }

        it { is_expected.to eq('error') }
      end
    end

    context 'with non successful response' do
      before do
        stub_import_status(path, nil, status_code: 404)
      end

      it { is_expected.to eq('pre_import_failed') }
    end
  end

  describe '#repository_details' do
    let(:path) { 'namespace/path/to/repository' }
    let(:response) { { foo: :bar, this: :is_a_test } }

    subject { client.repository_details(path, sizing: sizing) }

    [:self, :self_with_descendants, nil].each do |size_type|
      context "with sizing #{size_type}" do
        let(:sizing) { size_type }

        before do
          stub_repository_details(path, sizing: sizing, respond_with: response)
        end

        it { is_expected.to eq(response.stringify_keys.deep_transform_values(&:to_s)) }
      end
    end

    context 'with non successful response' do
      let(:sizing) { nil }

      before do
        stub_repository_details(path, sizing: sizing, status_code: 404)
      end

      it { is_expected.to eq({}) }
    end
  end

  describe '.supports_gitlab_api?' do
    subject { described_class.supports_gitlab_api? }

    where(:registry_gitlab_api_enabled, :is_on_dot_com, :container_registry_features, :expect_registry_to_be_pinged, :expected_result) do
      true  | true  | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | false | true
      true  | false | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | true  | true
      false | true  | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | false | true
      false | false | [described_class::REGISTRY_GITLAB_V1_API_FEATURE] | true  | false
      true  | true  | []                                                | true  | true
      true  | false | []                                                | true  | true
      false | true  | []                                                | true  | false
      false | false | []                                                | true  | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(is_on_dot_com)
        stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
        stub_registry_gitlab_api_support(registry_gitlab_api_enabled)
        stub_application_setting(container_registry_features: container_registry_features)
      end

      it 'returns the expected result' do
        if expect_registry_to_be_pinged
          expect(Faraday::Connection).to receive(:new).and_call_original
        else
          expect(Faraday::Connection).not_to receive(:new)
        end

        expect(subject).to be expected_result
      end
    end

    context 'with the registry disabled' do
      before do
        stub_container_registry_config(enabled: false, api_url: 'http://sandbox.local', key: 'spec/fixtures/x509_certificate_pk.key')
      end

      it 'returns false' do
        expect(Faraday::Connection).not_to receive(:new)

        expect(subject).to be_falsey
      end
    end

    context 'with a blank registry url' do
      before do
        stub_container_registry_config(enabled: true, api_url: '', key: 'spec/fixtures/x509_certificate_pk.key')
      end

      it 'returns false' do
        expect(Faraday::Connection).not_to receive(:new)

        expect(subject).to be_falsey
      end
    end
  end

  describe '.deduplicated_size' do
    let(:path) { 'foo/bar' }
    let(:response) { { 'size_bytes': 555 } }
    let(:registry_enabled) { true }

    subject { described_class.deduplicated_size(path) }

    before do
      stub_container_registry_config(enabled: registry_enabled, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
    end

    context 'with successful response' do
      before do
        expect(Auth::ContainerRegistryAuthenticationService).to receive(:pull_nested_repositories_access_token).with(path).and_return(token)
        stub_repository_details(path, sizing: :self_with_descendants, status_code: 200, respond_with: response)
      end

      it { is_expected.to eq(555) }
    end

    context 'with unsuccessful response' do
      before do
        expect(Auth::ContainerRegistryAuthenticationService).to receive(:pull_nested_repositories_access_token).with(path).and_return(token)
        stub_repository_details(path, sizing: :self_with_descendants, status_code: 404, respond_with: response)
      end

      it { is_expected.to eq(nil) }
    end

    context 'with the registry disabled' do
      let(:registry_enabled) { false }

      it { is_expected.to eq(nil) }
    end

    context 'with a nil path' do
      let(:path) { nil }
      let(:token) { nil }

      before do
        expect(Auth::ContainerRegistryAuthenticationService).not_to receive(:pull_nested_repositories_access_token)
        stub_repository_details(path, sizing: :self_with_descendants, status_code: 401, respond_with: response)
      end

      it { is_expected.to eq(nil) }
    end

    context 'with uppercase path' do
      let(:path) { 'foo/Bar' }

      before do
        expect(Auth::ContainerRegistryAuthenticationService).to receive(:pull_nested_repositories_access_token).with(path.downcase).and_return(token)
        stub_repository_details(path, sizing: :self_with_descendants, status_code: 200, respond_with: response)
      end

      it { is_expected.to eq(555) }
    end
  end

  def stub_pre_import(path, status_code, pre:)
    import_type = pre ? 'pre' : 'final'
    stub_request(:put, "#{registry_api_url}/gitlab/v1/import/#{path}/?import_type=#{import_type}")
      .with(headers: { 'Accept' => described_class::JSON_TYPE, 'Authorization' => "bearer #{import_token}" })
      .to_return(status: status_code, body: '')
  end

  def stub_registry_gitlab_api_support(supported = true)
    status_code = supported ? 200 : 404
    stub_request(:get, "#{registry_api_url}/gitlab/v1/")
      .with(headers: { 'Accept' => described_class::JSON_TYPE })
      .to_return(status: status_code, body: '')
  end

  def stub_import_status(path, status, status_code: 200)
    stub_request(:get, "#{registry_api_url}/gitlab/v1/import/#{path}/")
      .with(headers: { 'Accept' => described_class::JSON_TYPE, 'Authorization' => "bearer #{import_token}" })
      .to_return(
        status: status_code,
        body: { status: status }.to_json,
        headers: { content_type: 'application/json' }
      )
  end

  def stub_import_cancel(path, http_status, status: nil, force: false)
    body = {}

    if http_status == 400
      body = { status: status }
    end

    headers = {
      'Accept' => described_class::JSON_TYPE,
      'Authorization' => "bearer #{import_token}",
      'User-Agent' => "GitLab/#{Gitlab::VERSION}",
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3'
    }

    params = force ? '?force=true' : ''

    stub_request(:delete, "#{registry_api_url}/gitlab/v1/import/#{path}/#{params}")
      .with(headers: headers)
      .to_return(
        status: http_status,
        body: body.to_json,
        headers: { content_type: 'application/json' }
      )
  end

  def stub_repository_details(path, sizing: nil, status_code: 200, respond_with: {})
    url = "#{registry_api_url}/gitlab/v1/repositories/#{path}/"
    url += "?size=#{sizing}" if sizing

    headers = { 'Accept' => described_class::JSON_TYPE }
    headers['Authorization'] = "bearer #{token}" if token

    stub_request(:get, url)
      .with(headers: headers)
      .to_return(status: status_code, body: respond_with.to_json, headers: { 'Content-Type' => described_class::JSON_TYPE })
  end
end
