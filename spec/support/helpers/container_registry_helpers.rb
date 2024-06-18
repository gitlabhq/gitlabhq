# frozen_string_literal: true

module ContainerRegistryHelpers
  def stub_gitlab_api_client_to_support_gitlab_api(supported: true)
    allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(supported)
  end
end
