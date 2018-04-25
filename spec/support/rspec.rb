require_relative "helpers/stub_configuration"
require_relative "helpers/stub_object_storage"
require_relative "helpers/stub_env"

RSpec.configure do |config|
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.include StubConfiguration
  config.include StubObjectStorage
  config.include StubENV
end
