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

  describe '#import_status' do
    subject { client.import_status(path) }

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

  describe '#repository_details' do
    let(:path) { 'namespace/path/to/repository' }
    let(:response) { { foo: :bar, this: :is_a_test } }
    let(:with_size) { true }

    subject { client.repository_details(path, with_size: with_size) }

    context 'with size' do
      before do
        stub_repository_details(path, with_size: with_size, respond_with: response)
      end

      it { is_expected.to eq(response.stringify_keys.deep_transform_values(&:to_s)) }
    end

    context 'without_size' do
      let(:with_size) { false }

      before do
        stub_repository_details(path, with_size: with_size, respond_with: response)
      end

      it { is_expected.to eq(response.stringify_keys.deep_transform_values(&:to_s)) }
    end

    context 'with non successful response' do
      before do
        stub_repository_details(path, with_size: with_size, status_code: 404)
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

  def stub_import_status(path, status)
    stub_request(:get, "#{registry_api_url}/gitlab/v1/import/#{path}/")
      .with(headers: { 'Accept' => described_class::JSON_TYPE, 'Authorization' => "bearer #{import_token}" })
      .to_return(
        status: 200,
        body: { status: status }.to_json,
        headers: { content_type: 'application/json' }
      )
  end

  def stub_repository_details(path, with_size: true, status_code: 200, respond_with: {})
    url = "#{registry_api_url}/gitlab/v1/repositories/#{path}/"
    url += "?size=self" if with_size
    stub_request(:get, url)
      .with(headers: { 'Accept' => described_class::JSON_TYPE, 'Authorization' => "bearer #{token}" })
      .to_return(status: status_code, body: respond_with.to_json, headers: { 'Content-Type' => described_class::JSON_TYPE })
  end
end
