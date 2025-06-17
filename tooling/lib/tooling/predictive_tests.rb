# frozen_string_literal: true

require_relative 'find_changes'
require_relative 'find_tests'
require_relative 'find_files_using_feature_flags'
require_relative 'mappings/graphql_base_type_mappings'
require_relative 'mappings/js_to_system_specs_mappings'
require_relative 'mappings/partial_to_views_mappings'
require_relative 'mappings/view_to_js_mappings'
require_relative 'mappings/view_to_system_specs_mappings'
require_relative 'events/track_pipeline_events'
require_relative 'helpers/file_handler'

module Tooling
  class PredictiveTests
    include Helpers::FileHandler

    PREDICTIVE_TEST_METRICS_EVENT = 'glci_predictive_tests_metrics'
    RSPEC_ALL_FAILED_TESTS_FILE = 'rspec_all_failed_tests.txt'

    REQUIRED_ENV_VARIABLES = %w[
      RSPEC_CHANGED_FILES_PATH
      RSPEC_MATCHING_TEST_FILES_PATH
      RSPEC_VIEWS_INCLUDING_PARTIALS_PATH
      FRONTEND_FIXTURES_MAPPING_PATH
      RSPEC_MATCHING_JS_FILES_PATH
    ].freeze

    def initialize
      missing_env_variables = REQUIRED_ENV_VARIABLES.select { |key| ENV[key.to_s].to_s.empty? }
      unless missing_env_variables.empty?
        raise "[predictive tests] Missing ENV variable(s): #{missing_env_variables.join(',')}."
      end

      @rspec_changed_files_path            = ENV['RSPEC_CHANGED_FILES_PATH']
      @rspec_matching_test_files_path      = ENV['RSPEC_MATCHING_TEST_FILES_PATH']
      @rspec_views_including_partials_path = ENV['RSPEC_VIEWS_INCLUDING_PARTIALS_PATH']
      @frontend_fixtures_mapping_path      = ENV['FRONTEND_FIXTURES_MAPPING_PATH']
      @rspec_matching_js_files_path        = ENV['RSPEC_MATCHING_JS_FILES_PATH']
      @predictive_tests_strategy           = ENV['PREDICTIVE_TESTS_STRATEGY'] || 'described_class'

      @generate_metrics = ENV['GLCI_PREDICTIVE_TESTS_GENERATE_METRICS'] == 'true'
      @predictive_tests_track_events = ENV['GLCI_PREDICTIVE_TESTS_TRACK_EVENTS'] == 'true'
      @rspec_failed_tests_dir = ENV['GLCI_RSPEC_FAILED_TESTS_DIR']
      @crystalball_mapping_path = ENV['RSPEC_TESTS_MAPPING_PATH']
    end

    def execute
      execute_test_selection
      generate_and_record_metrics if @generate_metrics
    end

    def execute_test_selection
      Tooling::FindChanges.new(
        from: :api,
        changed_files_pathname: rspec_changed_files_path
      ).execute
      Tooling::FindFilesUsingFeatureFlags.new(changed_files_pathname: rspec_changed_files_path).execute
      Tooling::FindTests.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
      Tooling::Mappings::PartialToViewsMappings.new(
        rspec_changed_files_path, rspec_views_including_partials_path).execute
      Tooling::FindTests.new(rspec_views_including_partials_path, rspec_matching_test_files_path).execute
      Tooling::Mappings::JsToSystemSpecsMappings.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
      Tooling::Mappings::GraphqlBaseTypeMappings.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
      Tooling::Mappings::ViewToSystemSpecsMappings.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
      Tooling::FindChanges.new(
        from: :changed_files,
        changed_files_pathname: rspec_changed_files_path,
        predictive_tests_pathname: rspec_matching_test_files_path,
        frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_path
      ).execute
      Tooling::Mappings::ViewToJsMappings.new(rspec_changed_files_path, rspec_matching_js_files_path).execute
    end

    private

    attr_reader :rspec_changed_files_path,
      :rspec_matching_test_files_path,
      :rspec_views_including_partials_path,
      :frontend_fixtures_mapping_path,
      :rspec_matching_js_files_path,
      :predictive_tests_strategy,
      :generate_metrics,
      :rspec_failed_tests_file,
      :rspec_failed_tests_dir,
      :crystalball_mapping_path

    def generate_and_record_metrics
      puts "[predictive tests] Generating metrics..."

      @rspec_failed_tests_file = File.join(@rspec_failed_tests_dir, RSPEC_ALL_FAILED_TESTS_FILE)

      changed_files = read_array_from_file(rspec_changed_files_path)
      # based on the predictive test selection strategy
      predicted_test_files = read_array_from_file(rspec_matching_test_files_path)
      # actual failed tests from tier-3 run
      failed_test_files = read_array_from_file(rspec_failed_tests_file)

      metrics = generate_metrics_data(changed_files, predicted_test_files, failed_test_files)

      save_metrics(metrics)
      track_metrics_events(metrics) if @predictive_tests_track_events

      puts "[predictive tests] Metrics generation completed"
    rescue StandardError => e
      puts "[predictive tests] Warning: Metrics generation failed: #{e.message}"
      puts e.backtrace.first(5) if e.backtrace
    end

    def crystalball_mapping
      return @crystalball_mapping if @crystalball_mapping
      return @crystalball_mapping = {} unless crystalball_mapping_path && File.exist?(crystalball_mapping_path)

      @crystalball_mapping = JSON.parse(File.read(crystalball_mapping_path)) # rubocop:disable Gitlab/Json -- not in Rails environment
    rescue StandardError => e
      puts "[predictive tests] Warning: Failed to load crystalball mapping: #{e.message}"
      @crystalball_mapping = {}
    end

    def generate_metrics_data(changed_files, predicted_test_files, failed_test_files)
      predicted_test_files_set = predicted_test_files.to_set
      failed_set = failed_test_files.to_set

      # Core metrics
      missed_failing = (failed_set - predicted_test_files_set).size

      # Crystalball analysis
      test_files_selected_by_crystalball = get_test_files_selected_by_crystalball(changed_files)
      changed_files_in_mapping = changed_files_count_in_mapping(changed_files)

      {
        timestamp: Time.now.iso8601,
        strategy: predictive_tests_strategy,
        core_metrics: {
          changed_files_count: changed_files.size,
          predicted_test_files_count: predicted_test_files.size,
          missed_failing_test_files: missed_failing,
          changed_files_in_mapping: changed_files_in_mapping,
          failed_test_files_count: failed_test_files.size
        },
        mapping_metrics: {
          total_test_files_in_mapping: all_test_files_from_mapping.size,
          test_files_selected_by_crystalball: test_files_selected_by_crystalball.size,
          failed_test_files_in_mapping: (failed_set & all_test_files_from_mapping).size
        }
      }
    end

    def get_test_files_selected_by_crystalball(changed_files)
      changed_files
        .filter_map { |file| crystalball_mapping[file] }
        .flatten
        .to_set
    end

    def all_test_files_from_mapping
      @all_test_files_from_mapping ||= crystalball_mapping.values.flatten.to_set
    end

    def changed_files_count_in_mapping(changed_files)
      changed_files.count { |file| crystalball_mapping[file]&.any? }
    end

    def save_metrics(metrics)
      output_path = ENV['GLCI_PREDICTIVE_TESTS_METRICS_PATH'] || 'tmp/predictive_test_metrics.json'
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, JSON.pretty_generate(metrics)) # rubocop:disable Gitlab/Json -- not in Rails environment
    rescue StandardError => e
      puts "[predictive tests] Warning: Failed to save metrics: #{e.message}"
    end

    def track_metrics_events(metrics)
      tracker = Tooling::Events::TrackPipelineEvents.new
      core = metrics[:core_metrics]
      extra_properties = { ci_job_id: ENV["CI_JOB_ID"] }

      tracker.send_event(
        PREDICTIVE_TEST_METRICS_EVENT,
        label: "changed_files_count",
        value: core[:changed_files_count],
        property: predictive_tests_strategy,
        extra_properties: extra_properties
      )

      tracker.send_event(
        PREDICTIVE_TEST_METRICS_EVENT,
        label: "predicted_test_files_count",
        value: core[:predicted_test_files_count],
        property: predictive_tests_strategy,
        extra_properties: extra_properties
      )

      tracker.send_event(
        PREDICTIVE_TEST_METRICS_EVENT,
        label: "missed_failing_test_files",
        value: core[:missed_failing_test_files],
        property: predictive_tests_strategy,
        extra_properties: extra_properties
      )
    rescue StandardError => e
      puts "[predictive tests] Warning: Could not track metrics events: #{e.message}"
    end
  end
end
