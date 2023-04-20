# frozen_string_literal: true

require_relative "rspec_order"
require_relative "system_exit_detected"
require_relative "helpers/stub_configuration"
require_relative "helpers/stub_metrics"
require_relative "helpers/stub_object_storage"
require_relative "helpers/stub_env"
require_relative "helpers/fast_rails_root"

require_relative "../../lib/gitlab/utils"

RSpec::Expectations.configuration.on_potential_false_positives = :raise

RSpec.configure do |config|
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/379686
  config.threadsafe = false

  # Re-run failures locally with `--only-failures`
  config.example_status_persistence_file_path = ENV.fetch('RSPEC_LAST_RUN_RESULTS_FILE', './spec/examples.txt')

  # Makes diffs show entire non-truncated values.
  config.before(:each, :unlimited_max_formatted_output_length) do
    config.expect_with :rspec do |c|
      c.max_formatted_output_length = nil
    end
  end

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

  warn_missing_feature_category = Gitlab::Utils.to_boolean(ENV['RSPEC_WARN_MISSING_FEATURE_CATEGORY'], default: true)

  # Add warning for example missing feature_category
  config.before do |example|
    if warn_missing_feature_category && example.metadata[:feature_category].blank? && !ENV['CI']
      location =
        example.metadata[:shared_group_inclusion_backtrace].last&.formatted_inclusion_location ||
        example.location
      warn "Missing metadata feature_category: #{location} See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata"
    end
  end
end
