# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::GitlabApiClient do
  using RSpec::Parameterized::TableSyntax

  include_context 'container registry client'

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
          expect_next_instance_of(Faraday::Connection) do |connection|
            expect(connection).to receive(:run_request).and_call_original
          end
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
    let(:path) { 'namespace/path/to/repository' }

    subject { client.pre_import_repository('namespace/path/to/repository') }

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

  describe '#pre_import_repository' do
    let(:path) { 'namespace/path/to/repository' }

    subject { client.import_repository('namespace/path/to/repository') }

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
          expect_next_instance_of(Faraday::Connection) do |connection|
            expect(connection).to receive(:run_request).and_call_original
          end
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
    stub_request(:put, "#{registry_api_url}/gitlab/v1/import/#{path}?pre=#{pre}")
      .to_return(status: status_code, body: '')
  end

  def stub_registry_gitlab_api_support(supported = true)
    status_code = supported ? 200 : 404
    stub_request(:get, "#{registry_api_url}/gitlab/v1/")
      .to_return(status: status_code, body: '')
  end
end
