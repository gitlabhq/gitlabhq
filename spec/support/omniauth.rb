# frozen_string_literal: true

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  # Clean up global state leaked by `prepare_provider_route` (in LoginHelpers).
  # See LoginHelpers.cleanup_provider_routes for details on what is restored.
  config.after do |example|
    next unless example.metadata[:provider_routes_modified]

    LoginHelpers.cleanup_provider_routes
  end
end
