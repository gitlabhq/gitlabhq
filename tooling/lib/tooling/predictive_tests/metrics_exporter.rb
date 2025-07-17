# frozen_string_literal: true

require_relative "test_selector"
require_relative "changed_files"
require_relative "mapping_fetcher"

require_relative "../helpers/file_handler"
require_relative "../events/track_pipeline_events"
require_relative "../find_changes"

require "logger"
require "tmpdir"

module Tooling
  module PredictiveTests
    # Class responsible for running through the whole flow of creating a list of predictive tests
    # which is then exported for tracking purposes
    #
    #
    class MetricsExporter
      include Helpers::FileHandler

      PREDICTIVE_TEST_METRICS_EVENT = "glci_predictive_tests_metrics"
      STRATEGIES = [:coverage, :described_class].freeze
      TEST_TYPE = "backend"

      def initialize(rspec_all_failed_tests_file:, output_dir: nil)
        @rspec_all_failed_tests_file = rspec_all_failed_tests_file
        @output_dir = output_dir
        @logger = Logger.new($stdout, progname: "rspec predictive testing")
      end

      # Execute metrics export
      #
      # @return [void]
      def execute
        STRATEGIES.each do |strategy|
          logger.info("Running metrics export for '#{strategy}' strategy ...")
          generate_and_record_metrics(strategy)
        rescue StandardError => e
          logger.error("Failed to export test metrics for strategy '#{strategy}': #{e.message}")
          logger.error(e.backtrace.select { |entry| entry.include?(project_root) }) if e.backtrace
        end
      end

      private

      attr_reader :rspec_all_failed_tests_file, :logger

      # Project root folder
      #
      # @return [String]
      def project_root
        @project_root ||= File.expand_path("../../..", __dir__)
      end

      # Path for all output created by metrics exporter
      #
      # @return [String]
      def output_path
        return @output_path if @output_path

        path = @output_dir || ENV.fetch(OUTPUT_PATH_VAR, File.join(project_root, "tmp", "predictive_tests"))
        STRATEGIES.each { |strategy| FileUtils.mkdir_p(File.join(path, strategy.to_s)) }

        @output_path = path
      end

      # Internal event tracker
      #
      # @return [TrackPipelineEvents]
      def tracker
        @tracker ||= Tooling::Events::TrackPipelineEvents.new(logger: logger)
      end

      # MR changed files
      #
      # @return [String]
      def changed_files
        @changed_files ||= ChangedFiles.fetch(
          changes: Tooling::FindChanges.new(
            from: :api,
            frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_file
          ).execute
        )
      end

      # Mapping file fetcher
      #
      # @return [MappingFetcher]
      def mapping_fetcher
        @mapping_fetcher ||= Tooling::PredictiveTests::MappingFetcher.new(logger: logger)
      end

      # Frontend fixtures mapping file
      #
      # @return [String]
      def frontend_fixtures_mapping_file
        @frontend_fixtures_mapping_file ||= File.join(Dir.tmpdir, "frontend_fixtures_mapping.json").tap do |file|
          mapping_fetcher.fetch_frontend_fixtures_mappings(file)
        end
      end

      # Mapping file path for specific strategy
      #
      # @param strategy [Symbol]
      # @return [String]
      def mapping_file_path(strategy)
        File.join(Dir.tmpdir, strategy.to_s, "mapping.json")
      end

      # Strategy specific matching rspec tests file path
      #
      # @param strategy [Symbol]
      # @return [String]
      def matching_rspec_test_files_path(strategy)
        path_for_strategy(strategy, "rspec_matching_test_files.txt")
      end

      # Full path within strategy specific folder
      #
      # @param strategy [Symbol]
      # @param *args [Array] optional extra path parts to append
      # @return [String]
      def path_for_strategy(strategy, *args)
        File.join(output_path, strategy.to_s, *args)
      end

      # Predictive spec list selector
      #
      # @param strategy [Symbol]
      # @return [TestSelector]
      def test_selector(strategy)
        Tooling::PredictiveTests::TestSelector.new(
          changed_files: changed_files,
          rspec_test_mapping_path: mapping_file_path(strategy),
          rspec_mappings_limit_percentage: nil # always return all tests in the mapping
        )
      end

      # Create, save and export metrics for selected RSpec tests for specific strategy
      #
      # @param strategy [Symbol]
      # @return [void]
      def generate_and_record_metrics(strategy)
        logger.info("Generating metrics for mapping strategy '#{strategy}' ...")

        # fetch crystalball mappings for specific strategy
        fetch_crystalball_mappings!(strategy)
        # based on the predictive test selection strategy
        predicted_test_files = test_selector(strategy).rspec_spec_list
        # actual failed tests from tier-3 run
        failed_test_files = read_array_from_file(rspec_all_failed_tests_file)
        # crystalball mapping file
        crystalball_mapping = JSON.parse(File.read(mapping_file_path(strategy))) # rubocop:disable Gitlab/Json -- not in Rails environment

        metrics = generate_metrics_data(
          changed_files,
          predicted_test_files,
          failed_test_files,
          crystalball_mapping,
          strategy
        )

        save_metrics(metrics, strategy)
        send_metrics_events(metrics, strategy)

        logger.info("Metrics generation completed for strategy '#{strategy}'")
      end

      # Fetch crystalball mappings
      #
      # @param strategy [Symbol]
      # @return [void]
      def fetch_crystalball_mappings!(strategy)
        mapping_fetcher.fetch_rspec_mappings(mapping_file_path(strategy), type: strategy)
      end

      # Create metrics hash with all calculated metrics based on crystalball mapping and selected test strategy
      #
      # @param changed_files [Array]
      # @param predicted_test_files [Array]
      # @param failed_test_files [Array]
      # @param crystalball_mapping [Hash]
      # @param strategy [Symbol]
      # @return [Hash]
      def generate_metrics_data(changed_files, predicted_test_files, failed_test_files, crystalball_mapping, strategy)
        all_test_files_from_mapping = crystalball_mapping.values.flatten.uniq
        test_files_selected_by_crystalball = changed_files
          .filter_map { |file| crystalball_mapping[file] }
          .flatten

        {
          timestamp: Time.now.iso8601,
          strategy: strategy,
          core_metrics: {
            changed_files_count: changed_files.size,
            predicted_test_files_count: predicted_test_files.size,
            missed_failing_test_files: (failed_test_files - predicted_test_files).size,
            changed_files_in_mapping: changed_files.count { |file| crystalball_mapping[file]&.any? },
            failed_test_files_count: failed_test_files.size
          },
          mapping_metrics: {
            total_test_files_in_mapping: all_test_files_from_mapping.size,
            test_files_selected_by_crystalball: test_files_selected_by_crystalball.size,
            failed_test_files_in_mapping: (failed_test_files & all_test_files_from_mapping).size
          }
        }
      end

      # Save metrics hash as json file
      #
      # @param metrics [Hash]
      # @param strategy [Symbol]
      # @return [void]
      def save_metrics(metrics, strategy)
        File.write(File.join(output_path, "metrics_#{strategy}.json"), JSON.pretty_generate(metrics)) # rubocop:disable Gitlab/Json -- not in Rails environment
      end

      # Send events containing calculated predictive tests metrics
      #
      # @param metrics [Hash]
      # @param strategy [Symbol]
      # @return [void]
      def send_metrics_events(metrics, strategy)
        core = metrics[:core_metrics]
        extra_properties = { ci_job_id: ENV["CI_JOB_ID"], test_type: TEST_TYPE }

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "changed_files_count",
          value: core[:changed_files_count],
          property: strategy.to_s,
          extra_properties: extra_properties
        )

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "predicted_test_files_count",
          value: core[:predicted_test_files_count],
          property: strategy.to_s,
          extra_properties: extra_properties
        )

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "missed_failing_test_files",
          value: core[:missed_failing_test_files],
          property: strategy.to_s,
          extra_properties: extra_properties
        )
      end
    end
  end
end
