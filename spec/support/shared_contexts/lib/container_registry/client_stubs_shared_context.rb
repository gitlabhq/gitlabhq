# frozen_string_literal: true

RSpec.shared_context 'container registry client stubs' do
  def stub_container_registry_gitlab_api_support(supported: true)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(:supports_gitlab_api?).and_return(supported)
      yield client if block_given?
    end
  end

  def stub_container_registry_gitlab_api_repository_details(
    client, path:, size_bytes: 0, sizing: nil, last_published_at: nil)
    expected_params = [path]
    expected_params << { sizing: sizing } if sizing.present?

    allow(client).to receive(:repository_details)
      .with(*expected_params)
      .and_return('size_bytes' => size_bytes, 'last_published_at' => last_published_at)
  end

  def stub_container_registry_gitlab_api_network_error(client_method: :supports_gitlab_api?)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(client_method).and_raise(::Faraday::Error, nil, nil)
    end
  end
end
