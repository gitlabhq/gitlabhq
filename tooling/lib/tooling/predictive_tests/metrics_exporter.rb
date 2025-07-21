# frozen_string_literal: true

require_relative "test_selector"
require_relative "changed_files"
require_relative "mapping_fetcher"

require_relative "../helpers/file_handler"
require_relative "../events/track_pipeline_events"
require_relative "../find_changes"

require "logger"
require "tmpdir"
require "open3"

# rubocop:disable Gitlab/Json -- non-rails
module Tooling
  module PredictiveTests
    # Class responsible for running through the whole flow of creating a list of predictive tests
    # which is then exported for tracking purposes
    #
    #
    class MetricsExporter
      include Helpers::FileHandler

      # @return [String] script path for jest predictive tests list generation
      JEST_PREDICTIVE_TESTS_SCRIPT_PATH = "scripts/frontend/find_jest_predictive_tests.js"
      # @return [String] event name used by internal events
      PREDICTIVE_TEST_METRICS_EVENT = "glci_predictive_tests_metrics"
      # @return [Hash] Supported test types with strategies
      TEST_TYPES = {
        backend: [:coverage, :described_class],
        frontend: [:jest_built_in]
      }.freeze

      def initialize(test_type:, all_failed_tests_file:, log_level: :info, output_dir: nil)
        @test_type = test_type.tap do |type|
          raise "Unknown test type '#{type}'" unless TEST_TYPES.key?(type.to_sym)
        end

        @failed_test_files = read_array_from_file(all_failed_tests_file)
        @output_dir = output_dir || File.join(project_root, "tmp", "predictive_tests")

        @logger = Logger.new($stdout, level: log_level).tap do |l|
          l.formatter = proc do |severity, _datetime, _progname, msg|
            # remove datetime to keep more neat cli like output
            "[Metrics Export - #{test_type}] #{severity}: #{msg}\n"
          end
        end
      end

      # Execute metrics export
      #
      # @return [Boolean]
      def execute
        logger.info("Running metrics export for test type: #{test_type}")

        case test_type
        when :backend
          export_rspec_metrics
        when :frontend
          export_jest_metrics
        end
      end

      private

      attr_reader :failed_test_files, :test_type, :logger

      # Export rspec test metrics
      #
      # @return [Boolean]
      def export_rspec_metrics
        export_all_strategies(TEST_TYPES[:backend]) do |strategy|
          generate_and_record_metrics(strategy, rspec_matching_tests(strategy))
        end
      end

      # Export jest test metrics
      #
      # @return [Boolean]
      def export_jest_metrics
        export_all_strategies(TEST_TYPES[:frontend]) do |strategy|
          generate_and_record_metrics(strategy, jest_matching_tests)
        end
      end

      # Export metrics for all defined strategies
      #
      # @param strategies [Array]
      # @return [Boolean]
      def export_all_strategies(strategies)
        results = strategies.map do |strategy|
          logger.info("Running export for '#{strategy}' strategy")
          yield(strategy)
          true
        rescue StandardError => e
          logger.error("Failed to export test metrics for strategy '#{strategy}': #{e.message}")
          logger.error(e.backtrace.select { |entry| entry.include?(project_root) }.join("\n")) if e.backtrace
          false
        end

        results.all?(true)
      end

      # Project root folder
      #
      # @return [String]
      def project_root
        @project_root ||= File.expand_path("../../../..", __dir__)
      end

      # Path for specific test type output
      #
      # @return [String]
      def output_path
        @output_path ||= File.join(@output_dir, test_type.to_s).tap { |path| FileUtils.mkdir_p(path) }
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

      # Matching rspec tests generated via test selector
      #
      # @param strategy [Symbol]
      # @return [Array]
      def rspec_matching_tests(strategy)
        mapping_file = fetch_crystalball_mappings(strategy)
        test_selector(mapping_file).rspec_spec_list
      end

      # Matching jest tests generated via native js script
      #
      # @return [Array]
      def jest_matching_tests
        return @jest_matching_tests if @jest_matching_tests

        script = File.join(project_root, JEST_PREDICTIVE_TESTS_SCRIPT_PATH)
        result_path = File.join(Dir.tmpdir, "predictive_jest_matching_tests.txt")
        ruby_files = changed_files.reject do |f|
          Tooling::PredictiveTests::ChangedFiles::JS_FILE_FILTER_REGEX.match?(f)
        end
        js_files = changed_files - ruby_files

        logger.debug("Creating inputs for js predictive tests script")
        changed_ruby_files_path = File.join(Dir.tmpdir, "changed_files.txt").tap do |f|
          File.write(f, ruby_files.join("\n"))
        end
        matching_js_files_path = File.join(Dir.tmpdir, "matching_js_files.txt").tap do |f|
          File.write(f, js_files.join("\n"))
        end

        logger.info("Generating predictive jest test file list via '#{script}'")
        out, status = Open3.capture2e({
          "RSPEC_CHANGED_FILES_PATH" => changed_ruby_files_path,
          'RSPEC_MATCHING_JS_FILES_PATH' => matching_js_files_path,
          'JEST_MATCHING_TEST_FILES_PATH' => result_path
        }, script)
        raise "Failed to generate jest matching tests via #{script}, output: #{out}" unless status.success?

        logger.debug("Jest predictive test creation script output:\n#{out}")
        @jest_matching_tests = read_array_from_file(result_path).tap do |list|
          logger.info("Generated following jest predictive test file list: #{JSON.pretty_generate(list)}")
        end
      end

      # Mapping file path for specific strategy
      #
      # @param strategy [Symbol]
      # @return [String]
      def backend_mapping_file_path(strategy)
        File.join(Dir.tmpdir, "#{strategy}_mapping.json")
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
      def test_selector(rspec_test_mapping_path = nil)
        Tooling::PredictiveTests::TestSelector.new(
          changed_files: changed_files,
          rspec_test_mapping_path: rspec_test_mapping_path,
          logger: logger,
          rspec_mappings_limit_percentage: nil # always return all tests in the mapping,
        )
      end

      # Create, save and export metrics for selected RSpec tests for specific strategy
      #
      # @param strategy [Symbol]
      # @return [void]
      def generate_and_record_metrics(strategy, predicted_test_files)
        logger.info("Generating metrics for mapping strategy '#{strategy}' ...")

        metrics = generate_metrics_data(
          changed_files,
          predicted_test_files,
          strategy
        )

        save_metrics(metrics, strategy)
        send_metrics_events(metrics, strategy)

        logger.info("Metrics generation completed for strategy '#{strategy}'")
      end

      # Fetch crystalball mappings and return file location
      #
      # @param strategy [Symbol]
      # @return [String]
      def fetch_crystalball_mappings(strategy)
        backend_mapping_file_path(strategy).tap do |file|
          mapping_fetcher.fetch_rspec_mappings(file, type: strategy)
        end
      end

      # Create metrics hash with all calculated metrics
      #
      # @param changed_files [Array]
      # @param predicted_test_files [Array]
      # @param strategy [Symbol]
      # @return [Hash]
      def generate_metrics_data(changed_files, predicted_test_files, strategy)
        {
          timestamp: Time.now.iso8601,
          test_type: test_type,
          strategy: strategy,
          core_metrics: {
            changed_files_count: changed_files.size,
            predicted_test_files_count: predicted_test_files.size,
            missed_failing_test_files: (failed_test_files - predicted_test_files).size,
            failed_test_files_count: failed_test_files.size
          }
        }
      end

      # Save metrics hash as json file
      #
      # @param metrics [Hash]
      # @param strategy [Symbol]
      # @return [void]
      def save_metrics(metrics, strategy)
        File.write(File.join(output_path, "metrics_#{strategy}.json"), JSON.pretty_generate(metrics))
      end

      # Send events containing calculated predictive tests metrics
      #
      # @param metrics [Hash]
      # @param strategy [Symbol]
      # @return [void]
      def send_metrics_events(metrics, strategy)
        core = metrics[:core_metrics]
        extra_properties = { ci_job_id: ENV["CI_JOB_ID"], test_type: test_type }

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
# rubocop:enable Gitlab/Json
