# frozen_string_literal: true

require_relative "test_selector"
require_relative "changed_files"
require_relative "mapping_fetcher"

require_relative "../helpers/file_handler"
require_relative "../find_changes"

require "logger"
require "tmpdir"
require "open3"
require "gitlab_quality/test_tooling/click_house/client"

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
      REQUIRED_CLICKHOUSE_ENV_VARS = %w[
        GLCI_DA_CLICKHOUSE_URL
        GLCI_CLICKHOUSE_METRICS_USERNAME
        GLCI_CLICKHOUSE_METRICS_PASSWORD
        GLCI_CLICKHOUSE_METRICS_DB
        GLCI_PREDICTIVE_TESTS_CLICKHOUSE_TABLE
      ].freeze
      # @return [Hash] Supported test types with strategies
      TEST_TYPES = {
        backend: [:coverage, :described_class],
        frontend: [:jest_built_in]
      }.freeze
      # @return [Integer] default spec runtime for tracking purposes
      DEFAULT_SPEC_RUNTIME_SECONDS = 0
      # @return [Array] feature spec path prefixes (system tests)
      FEATURE_SPEC_PREFIXES = %w[spec/features/ ee/spec/features/].freeze

      def initialize(
        test_type:,
        all_failed_tests_file:,
        test_runtime_report_file: nil,
        log_level: :info,
        output_dir: nil
      )
        @test_type = test_type.tap do |type|
          raise "Unknown test type '#{type}'" unless TEST_TYPES.key?(type.to_sym)
        end

        @failed_test_files = read_array_from_file(all_failed_tests_file)
        @output_dir = output_dir || File.join(project_root, "tmp", "predictive_tests")
        @test_runtime_report_file = test_runtime_report_file

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

      attr_reader :failed_test_files, :test_runtime_report_file, :test_type, :logger

      # Export rspec test metrics
      #
      # @return [Boolean]
      def export_rspec_metrics
        result = export_all_strategies(TEST_TYPES[:backend]) do |strategy|
          generate_and_record_metrics(strategy, rspec_matching_tests(strategy))
        end

        export_duo_metrics

        result
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

      # Export Duo metrics by reading from artifact written by detect-system-tests-duo-experiment.
      #
      # Duo is intentionally NOT re-invoked here because:
      # 1. It would incur additional LLM API costs
      # 2. The LLM response is non-deterministic - a second call could return different
      #    specs than what was actually used for test selection, making metrics misleading
      #
      # Instead, the detect-system-tests-duo-experiment job saves its predictions to a file which
      # is passed to this job as an artifact via GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH.
      #
      # Note: missed_failing_test_files is calculated against feature specs only, since
      # Duo exclusively predicts feature specs.
      #
      # @return [void]
      def export_duo_metrics
        system_tests_file = ENV['GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH']

        unless system_tests_file
          logger.info("Skipping Duo metrics - GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH not set")
          return
        end

        unless File.exist?(system_tests_file)
          logger.warn("Skipping Duo metrics - artifact file not found (#{system_tests_file})")
          return
        end

        predicted_tests = read_array_from_file(system_tests_file)
        predicted_failing = (predicted_tests & duo_failed_test_files).size
        logger.info("Duo predicted #{predicted_failing} out of #{duo_failed_test_files.size} feature spec failures " \
          "| #{failed_test_files.size} total test failures")

        generate_and_record_metrics(:duo, predicted_tests, scoped_failed_files: duo_failed_test_files)
      rescue StandardError => e
        logger.error("Failed to export Duo metrics: #{e.message}")
        logger.error(e.backtrace.select { |entry| entry.include?(project_root) }.join("\n")) if e.backtrace
      end

      # Failed test files scoped to feature specs only.
      #
      # Duo only predicts feature specs, so recall/miss metrics must be calculated
      # against this subset rather than all pipeline failures.
      #
      # @return [Array]
      def duo_failed_test_files
        @duo_failed_test_files ||= failed_test_files.select do |f|
          FEATURE_SPEC_PREFIXES.any? { |prefix| f.start_with?(prefix) }
        end
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
          "GLCI_PREDICTIVE_CHANGED_FILES_PATH" => changed_ruby_files_path,
          'GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH' => matching_js_files_path,
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
      # @param predicted_test_files [Array]
      # @param scoped_failed_files [Array] failed test files to calculate misses against
      # @return [void]
      def generate_and_record_metrics(strategy, predicted_test_files, scoped_failed_files: failed_test_files)
        logger.info("Generating metrics for mapping strategy '#{strategy}' ...")

        metrics = generate_metrics_data(
          changed_files,
          predicted_test_files,
          strategy,
          scoped_failed_files: scoped_failed_files
        )

        save_metrics(metrics, strategy)
        send_clickhouse_metrics(metrics, strategy)

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
      # @param scoped_failed_files [Array] failed test files to calculate misses against;
      #   defaults to all failed files but can be scoped to a subset (e.g. feature specs for Duo)
      # @return [Hash]
      def generate_metrics_data(changed_files, predicted_test_files, strategy, scoped_failed_files: failed_test_files)
        {
          timestamp: Time.now.iso8601,
          test_type: test_type,
          strategy: strategy,
          core_metrics: {
            changed_files_count: changed_files.size,
            predicted_test_files_count: predicted_test_files.size,
            missed_failing_test_files: (scoped_failed_files - predicted_test_files).size,
            predicted_failing_test_files: (scoped_failed_files & predicted_test_files).size,
            failed_test_files_count: scoped_failed_files.size,
            # rspec tests have runtime information provided via knapsack report
            # frontend tests don't have a runtime report yet, so we skip them
            runtime_metrics: runtime_metrics(predicted_test_files)
          }.compact
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

      # Send metrics to ClickHouse
      #
      # @param metrics [Hash]
      # @param strategy [Symbol]
      # @return [void]
      def send_clickhouse_metrics(metrics, strategy)
        unless environment_variables_set?
          missing = REQUIRED_CLICKHOUSE_ENV_VARS.reject { |var| ENV[var] && !ENV[var].empty? }
          logger.warn("ClickHouse export skipped - missing env vars: #{missing.join(', ')}")
          return
        end

        core = metrics[:core_metrics]
        runtime = core[:runtime_metrics] || {}

        row = {
          timestamp: metrics[:timestamp],
          test_type: test_type.to_s,
          strategy: strategy.to_s,
          ci_job_id: ENV["CI_JOB_ID"].to_i,
          ci_pipeline_id: ENV["CI_PIPELINE_ID"].to_i,
          ci_project_id: ENV["CI_PROJECT_ID"].to_i,
          ci_project_path: ENV["CI_PROJECT_PATH"].to_s,
          ci_merge_request_iid: ENV["CI_MERGE_REQUEST_IID"].to_i,
          changed_files_count: core[:changed_files_count],
          predicted_test_files_count: core[:predicted_test_files_count],
          missed_failing_test_files: core[:missed_failing_test_files],
          predicted_failing_test_files: core[:predicted_failing_test_files],
          failed_test_files_count: core[:failed_test_files_count],
          projected_test_runtime_seconds: runtime[:projected_test_runtime_seconds] || 0,
          test_files_missing_runtime_count: runtime[:test_files_missing_runtime_count] || 0
        }

        clickhouse_client.insert_json_data(ENV["GLCI_PREDICTIVE_TESTS_CLICKHOUSE_TABLE"], [row])
        logger.info("Successfully exported metrics to ClickHouse for strategy '#{strategy}'")
      end

      # @return [Boolean]
      def environment_variables_set?
        REQUIRED_CLICKHOUSE_ENV_VARS.all? { |var| ENV[var] && !ENV[var].empty? }
      end

      # @return [GitlabQuality::TestTooling::ClickHouse::Client]
      def clickhouse_client
        @clickhouse_client ||= GitlabQuality::TestTooling::ClickHouse::Client.new(
          url: ENV["GLCI_DA_CLICKHOUSE_URL"],
          database: ENV["GLCI_CLICKHOUSE_METRICS_DB"],
          username: ENV["GLCI_CLICKHOUSE_METRICS_USERNAME"],
          password: ENV["GLCI_CLICKHOUSE_METRICS_PASSWORD"],
          logger: logger
        )
      end

      # Create projected test runtime metrics hash for rspec tests based on knapsack report
      #
      # @param predicted_test_files [Array]
      # @return [Hash]
      def runtime_metrics(predicted_test_files)
        return if knapsack_report.empty? || test_type == :frontend

        specs_missing_runtime = []
        predicted_test_runtime_seconds = predicted_test_files.sum do |spec|
          if knapsack_report[spec]
            # round the value to 4 digits after to avoid very big floats in the output
            knapsack_report[spec].round(4)
          else
            specs_missing_runtime << spec
            DEFAULT_SPEC_RUNTIME_SECONDS
          end
        end

        {
          projected_test_runtime_seconds: predicted_test_runtime_seconds,
          test_files_missing_runtime_count: specs_missing_runtime.size
        }
      end

      # Knapsack report from CI environment which maps specs to runtime
      # Used to create project test runtime metric for predictive rspec tests
      #
      # @return [Hash]
      def knapsack_report
        return @knapsack_report if @knapsack_report
        return @knapsack_report = {} unless test_runtime_report_file && File.exist?(test_runtime_report_file)

        @knapsack_report = JSON.parse(File.read(test_runtime_report_file)) # rubocop:disable Gitlab/Json -- not in Rails environment
      rescue JSON::ParserError, Errno::ENOENT, Errno::EACCES => e
        logger.error("Failed to parse knapsack report #{e.message}")
        logger.error(e.backtrace.select { |entry| entry.include?(project_root) }) if e.backtrace
        @knapsack_report = {}
      end
    end
  end
end
# rubocop:enable Gitlab/Json
