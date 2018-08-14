require_relative "helpers/stub_configuration"
require_relative "helpers/stub_metrics"
require_relative "helpers/stub_object_storage"
require_relative "helpers/stub_env"

RSpec.configure do |config|
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.include StubConfiguration
  config.include StubMetrics
  config.include StubObjectStorage
  config.include StubENV

  config.fixture_path = Rails.root if defined?(Rails)
end
