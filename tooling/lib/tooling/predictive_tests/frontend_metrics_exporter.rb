# frozen_string_literal: true

require_relative "test_selector"
require_relative "../helpers/file_handler"
require_relative "../events/track_pipeline_events"

require "logger"

module Tooling
  module PredictiveTests
    class FrontendMetricsExporter
      include Helpers::FileHandler

      TEST_TYPE = 'frontend'
      DEFAULT_STRATEGY = "jest_built_in"
      JS_FILE_FILTER_REGEX = /\.(js|json|vue|ts|tsx)$/
      PREDICTIVE_TEST_METRICS_EVENT = "glci_predictive_tests_metrics"
      JEST_PREDICTIVE_TESTS_SCRIPT_PATH = "scripts/frontend/find_jest_predictive_tests.js"

      def initialize(
        rspec_changed_files_path:,
        rspec_matching_js_files_path:,
        jest_failed_test_files_path:,
        output_dir: nil
      )
        @rspec_changed_files_path = rspec_changed_files_path
        @rspec_matching_js_files_path = rspec_matching_js_files_path
        @jest_failed_test_files_path = jest_failed_test_files_path
        @output_dir = output_dir
        @logger = Logger.new($stdout, progname: "jest predictive testing")
      end

      def execute
        logger.info("Running frontend metrics export...")

        # If Jest script generation fails, just return early
        unless generate_jest_predictive_tests
          logger.info("Skipping metrics export due to Jest script issues")
          return
        end

        metrics = generate_metrics_data
        save_metrics(metrics)
        send_metrics_events(metrics)

        logger.info("Frontend metrics export completed")
      rescue StandardError => e
        logger.error("Failed to export frontend metrics: #{e.message}")
        logger.error(e.backtrace.select { |entry| entry.include?(project_root) }) if e.backtrace
      end

      private

      attr_reader :rspec_changed_files_path, :rspec_matching_js_files_path, :jest_failed_test_files_path, :output_dir,
        :logger

      def project_root
        @project_root ||= File.expand_path("../../../..", __dir__)
      end

      def output_path
        @output_path ||= File.join(output_dir, "frontend").tap { |path| FileUtils.mkdir_p(path) }
      end

      def tracker
        @tracker ||= Tooling::Events::TrackPipelineEvents.new(logger: logger)
      end

      def jest_matching_test_files_path
        @jest_matching_test_files_path ||= File.join(output_path, "jest_matching_test_files.txt")
      end

      def generate_jest_predictive_tests
        logger.info("Generating Jest predictive test list...")

        script_path = File.join(project_root, JEST_PREDICTIVE_TESTS_SCRIPT_PATH)
        unless File.exist?(script_path)
          logger.warn("Jest predictive test script not found at #{script_path}")
          return false # Return false instead of continuing
        end

        # Set environment variables for the Jest script
        env = {
          # get these artifacts from previous job
          'RSPEC_CHANGED_FILES_PATH' => rspec_changed_files_path,
          'RSPEC_MATCHING_JS_FILES_PATH' => rspec_matching_js_files_path,
          # path to save predictive jest files
          'JEST_MATCHING_TEST_FILES_PATH' => jest_matching_test_files_path
        }

        success = system(env, script_path)

        unless success
          logger.error("Failed to generate Jest predictive tests")
          return false
        end

        true
      end

      def generate_metrics_data
        logger.info("Generating frontend metrics data...")

        changed_files = read_array_from_file(rspec_changed_files_path)
        changed_js_files = changed_files.select { |f| f.match?(JS_FILE_FILTER_REGEX) }
        backend_triggered_js_files = read_array_from_file(rspec_matching_js_files_path)
        predicted_frontend_test_files = read_array_from_file(jest_matching_test_files_path)
        failed_frontend_test_files = read_array_from_file(jest_failed_test_files_path)
        missed_failing_test_files = (failed_frontend_test_files - predicted_frontend_test_files).size

        {
          timestamp: Time.now.iso8601,
          test_framework: 'jest',
          core_metrics: {
            changed_files_count: changed_files.size,
            predicted_test_files_count: predicted_frontend_test_files.size,
            missed_failing_test_files: missed_failing_test_files,
            changed_js_files_count: changed_js_files.size,
            backend_triggered_js_files_count: backend_triggered_js_files.size
          }
        }
      end

      def save_metrics(metrics)
        metrics_file = File.join(output_path, "metrics_frontend.json")
        File.write(metrics_file, JSON.pretty_generate(metrics)) # rubocop:disable Gitlab/Json -- not in Rails environment
        logger.info("Frontend metrics saved to #{metrics_file}")
      end

      def send_metrics_events(metrics)
        core = metrics[:core_metrics]
        extra_properties = {
          ci_job_id: ENV["CI_JOB_ID"],
          test_type: TEST_TYPE
        }

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "changed_files_count",
          value: core[:changed_files_count],
          property: DEFAULT_STRATEGY,
          extra_properties: extra_properties
        )

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "predicted_test_files_count",
          value: core[:predicted_test_files_count],
          property: DEFAULT_STRATEGY,
          extra_properties: extra_properties
        )

        tracker.send_event(
          PREDICTIVE_TEST_METRICS_EVENT,
          label: "missed_failing_test_files",
          value: core[:missed_failing_test_files],
          property: DEFAULT_STRATEGY,
          extra_properties: extra_properties
        )
      end
    end
  end
end
