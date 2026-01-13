# frozen_string_literal: true

module ContainerRegistryHelpers
  def stub_gitlab_api_client_to_support_gitlab_api(supported: true)
    allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(supported)
    return if supported

    # rubocop:disable RSpec/AnyInstanceOf -- need to stub calls from all instances
    # Only stub if not supported to save API call otherwise, call original API.
    allow_any_instance_of(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(false)
    # rubocop:enable RSpec/AnyInstanceOf
  end
end
