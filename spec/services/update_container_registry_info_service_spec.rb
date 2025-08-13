# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateContainerRegistryInfoService, feature_category: :container_registry do
  let_it_be_with_reload(:application_settings) { Gitlab::CurrentSettings }
  let_it_be(:api_url) { 'http://registry.gitlab' }

  describe '#execute' do
    before do
      stub_access_token
      stub_container_registry_config(enabled: true, api_url: api_url)
    end

    subject { described_class.new.execute }

    shared_examples 'invalid config' do
      it 'does not update the application settings' do
        expect(application_settings).not_to receive(:update!)

        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    shared_examples 'querying the /v2 route of the registry' do
      let(:token) { 'foo' }
      let(:client) { ContainerRegistry::Client.new(api_url, token: token) }
      let(:registry_info) { { vendor: 'other', version: '123', features: nil, db_enabled: false } }

      before do
        stub_registry_info(registry_info)
      end

      it 'uses a token with no access permissions' do
        expect(Auth::ContainerRegistryAuthenticationService)
          .to receive(:access_token).with({}).and_return(token)
        expect(ContainerRegistry::Client)
          .to receive(:new).with(api_url, token: token).and_return(client)

        subject
      end

      it 'updates application settings accordingly' do
        subject

        expect(application_settings).to have_attributes(
          container_registry_vendor: 'other',
          container_registry_version: '123',
          container_registry_features: [],
          container_registry_db_enabled: false
        )
      end

      context 'when the client returns an empty hash' do
        let(:registry_info) { {} }

        it 'sets the application settings to their defaults' do
          subject

          expect(application_settings).to have_attributes(
            container_registry_vendor: '',
            container_registry_version: '',
            container_registry_features: [],
            container_registry_db_enabled: false
          )
        end
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it_behaves_like 'invalid config'
    end

    context 'when container registry api_url is blank' do
      before do
        stub_container_registry_config(api_url: '')
      end

      it_behaves_like 'invalid config'
    end

    context 'when the Gitlab API is supported' do
      before do
        allow(Auth::ContainerRegistryAuthenticationService).to receive(:statistics_token).and_return('foo')
        allow(ContainerRegistry::GitlabApiClient).to receive_messages(supports_gitlab_api?: true,
          statistics: api_return_value)
      end

      context 'when the Gitlab API client returns the statistics' do
        let(:api_return_value) do
          { features: %w[a b], version: '1.0', db_enabled: true }
        end

        it 'calls the Gitlab API for statistics' do
          subject

          expect(application_settings).to have_attributes(
            container_registry_vendor: 'gitlab',
            container_registry_version: '1.0',
            container_registry_features: %W[a b #{ContainerRegistry::GitlabApiClient::REGISTRY_GITLAB_V1_API_FEATURE}],
            container_registry_db_enabled: true
          )
        end
      end

      context 'when the Gitlab API client returns an empty hash' do
        let(:api_return_value) { {} }

        it 'sets the application settings to defaults' do
          subject

          expect(application_settings).to have_attributes(
            container_registry_vendor: 'gitlab',
            container_registry_version: '',
            container_registry_features: [ContainerRegistry::GitlabApiClient::REGISTRY_GITLAB_V1_API_FEATURE],
            container_registry_db_enabled: false
          )
        end
      end
    end

    context 'when the Gitlab API is not supported' do
      before do
        stub_supports_gitlab_api(false)
      end

      it_behaves_like 'querying the /v2 route of the registry'
    end

    context 'when the feature use_registry_statistics_endpoint is disabled' do
      before do
        stub_feature_flags(use_registry_statistics_endpoint: false)
      end

      context 'when the Gitlab API is not supported' do
        before do
          stub_supports_gitlab_api(false)
        end

        it_behaves_like 'querying the /v2 route of the registry'
      end

      context 'when the Gitlab API is supported' do
        before do
          stub_registry_info(vendor: 'gitlab', version: '2.9.1-gitlab', features: %w[a b c], db_enabled: true)
          stub_supports_gitlab_api(true)
        end

        it 'updates application settings accordingly and adds the API feature to the feature list' do
          subject

          expect(application_settings).to have_attributes(
            container_registry_vendor: 'gitlab',
            container_registry_version: '2.9.1-gitlab',
            container_registry_features: %W[a b c
              #{ContainerRegistry::GitlabApiClient::REGISTRY_GITLAB_V1_API_FEATURE}],
            container_registry_db_enabled: true
          )
        end
      end
    end
  end

  def stub_access_token
    allow(Auth::ContainerRegistryAuthenticationService)
      .to receive(:access_token).with({}).and_return('foo')
  end

  def stub_registry_info(output)
    allow_next_instance_of(ContainerRegistry::Client) do |client|
      allow(client).to receive(:registry_info).and_return(output)
    end
  end

  def stub_supports_gitlab_api(output)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(:supports_gitlab_api?).and_return(output)
    end
  end
end
