# frozen_string_literal: true

RSpec.shared_context 'container registry client stubs' do
  def stub_container_registry_gitlab_api_support(supported: true)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(:supports_gitlab_api?).and_return(supported)
      yield client if block_given?
    end
  end

  def stub_container_registry_gitlab_api_repository_details(client, path:, size_bytes:, sizing: :self)
    allow(client).to receive(:repository_details).with(path, sizing: sizing).and_return('size_bytes' => size_bytes)
  end

  def stub_container_registry_gitlab_api_network_error(client_method: :supports_gitlab_api?)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(client_method).and_raise(::Faraday::Error, nil, nil)
    end
  end
end
