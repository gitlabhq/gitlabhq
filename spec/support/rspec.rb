# frozen_string_literal: true

require_relative "helpers/stub_configuration"
require_relative "helpers/stub_metrics"
require_relative "helpers/stub_object_storage"
require_relative "helpers/stub_env"
require_relative "helpers/fast_rails_root"

# so we need to load rubocop here due to the rubocop support file loading cop_helper
# which monkey patches class Cop
# if cop helper is loaded before rubocop (where class Cop is defined as class Cop < Base)
# we get a `superclass mismatch for class Cop` error when running a rspec for a locally defined
# rubocop cop - therefore we need rubocop required first since it had an inheritance added to the Cop class
require 'rubocop'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.include StubConfiguration
  config.include StubMetrics
  config.include StubObjectStorage
  config.include StubENV
  config.include FastRailsRoot

  config.include RuboCop::RSpec::ExpectOffense, type: :rubocop

  config.define_derived_metadata(file_path: %r{spec/rubocop}) do |metadata|
    metadata[:type] = :rubocop
  end
end
