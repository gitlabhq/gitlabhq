# frozen_string_literal: true

module GitlabSubscriptions
  module InternalApiHelpers
    def internal_api(path)
      "/api/#{::API::API.version}/internal/gitlab_subscriptions/#{path}"
    end

    def internal_api_headers
      { 'X-Customers-Dot-Internal-Token' => 'internal-api-token' }
    end

    def stub_internal_api_authentication
      allow(GitlabSubscriptions::API::Internal::Auth)
        .to receive(:verify_api_request)
        .with(hash_including(**internal_api_headers))
        .and_return(['decoded-token'])
    end
  end
end
