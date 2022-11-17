# frozen_string_literal: true

require_relative "rspec_order"
require_relative "system_exit_detected"
require_relative "helpers/stub_configuration"
require_relative "helpers/stub_metrics"
require_relative "helpers/stub_object_storage"
require_relative "helpers/stub_env"
require_relative "helpers/fast_rails_root"

RSpec::Expectations.configuration.on_potential_false_positives = :raise

RSpec.configure do |config|
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/379686
  config.threadsafe = false

  # Re-run failures locally with `--only-failures`
  config.example_status_persistence_file_path = ENV.fetch('RSPEC_LAST_RUN_RESULTS_FILE', './spec/examples.txt')

  unless ENV['CI']
    # Allow running `:focus` examples locally,
    # falling back to all tests when there is no `:focus` example.
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end

  config.raise_errors_for_deprecations!

  config.include StubConfiguration
  config.include StubMetrics
  config.include StubObjectStorage
  config.include StubENV
  config.include FastRailsRoot
end
