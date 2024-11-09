# frozen_string_literal: true

require_relative 'rake'
require_relative 'rspec_order'
require_relative 'rspec_run_time'
require_relative 'rspec_metadata_validator'
require_relative 'system_exit_detected'
require_relative 'helpers/stub_configuration'
require_relative 'helpers/stub_metrics'
require_relative 'helpers/stub_object_storage'
require_relative 'helpers/fast_rails_root'

require 'gitlab/rspec/all'
require 'gitlab/utils/all'

RSpec::Expectations.configuration.on_potential_false_positives = :raise

RSpec.configure do |config|
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/379686
  config.threadsafe = false

  # Re-run failures locally with `--only-failures`
  config.example_status_persistence_file_path = ENV.fetch('RSPEC_LAST_RUN_RESULTS_FILE', './spec/examples.txt')

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_spec\.rb\z}) do |metadata|
    # Infer metadata tag `type` if not already inferred by
    # `infer_spec_type_from_file_location!`.
    unless metadata.key?(:type)
      match = %r{/spec/([^/]+)/}.match(metadata[:location])
      metadata[:type] = match[1].singularize.to_sym if match
    end
  end

  config.before do |example|
    RspecMetadataValidator.validate!(example.metadata)
  end

  # Makes diffs show entire non-truncated values.
  config.around(:each, :unlimited_max_formatted_output_length) do |example|
    old_max_formatted_output_length = RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length

    config.expect_with :rspec do |c|
      c.max_formatted_output_length = nil
    end

    example.run

    config.expect_with :rspec do |c|
      c.max_formatted_output_length = old_max_formatted_output_length
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
