# frozen_string_literal: true

require 'os'
require 'yaml'
require 'rspec/core/formatters/base_formatter'
require_relative '../../tooling/lib/tooling/helpers/duration_formatter'

module Support
  module RSpecRunTime
    class RSpecFormatter < RSpec::Core::Formatters::BaseFormatter
      include Tooling::Helpers::DurationFormatter

      TIME_LIMIT_IN_MINUTES = Integer(ENV['RSPEC_TIME_LIMIT_IN_MINUTES'] || 80)

      RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished

      def start(_notification)
        @group_level = 0
        @rspec_test_suite_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        output.puts "\n# [RSpecRunTime] Starting RSpec timer..."

        init_expected_duration_report
      end

      def example_group_started(notification)
        if @last_elapsed_seconds && @last_elapsed_seconds > TIME_LIMIT_IN_MINUTES * 60
          RSpec::Expectations.fail_with(
            "Rspec suite is exceeding the #{TIME_LIMIT_IN_MINUTES} minute limit and is forced to exit with error.")
        end

        if @group_level == 0
          @current_group_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          file_path = spec_file_path(notification)
          output.puts "# [RSpecRunTime] Starting example group #{file_path}. #{expected_run_time(file_path)}"
        end

        @group_level += 1
      end

      def example_group_finished(notification)
        @group_level -= 1 if @group_level > 0

        if @group_level == 0
          file_path = spec_file_path(notification)
          time_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          actual_duration = time_now - @current_group_start_time

          output.puts "\n# [RSpecRunTime] Finishing example group #{file_path}. " \
                      "It took #{readable_duration(actual_duration)}. " \
                      "#{expected_run_time(file_path)}"
        end

        output_elapsed_time
      end

      private

      def expected_duration_report
        report_path = ENV['KNAPSACK_RSPEC_SUITE_REPORT_PATH']

        return unless report_path && File.exist?(report_path)

        # rubocop:disable Gitlab/Json -- regular JSON is sufficient
        @expected_duration_report ||= JSON.parse(File.read(report_path))
        # rubocop:enable Gitlab/Json
      end
      alias_method :init_expected_duration_report, :expected_duration_report

      def spec_file_path(notification)
        notification.group.metadata[:file_path].sub('./', '')
      end

      def expected_run_time(spec_file_path)
        return '' unless expected_duration_report

        expected_duration = expected_duration_report[spec_file_path]
        return "Missing expected duration from Knapsack report for #{spec_file_path}." unless expected_duration

        "Expected to take #{readable_duration(expected_duration)}."
      end

      def output_elapsed_time
        time_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed_seconds = time_now - @rspec_test_suite_start_time

        # skip the output unless the duration increased by at least 1 second
        unless @last_elapsed_seconds.nil? || elapsed_seconds - @last_elapsed_seconds < 1
          output.puts \
            "# [RSpecRunTime] RSpec elapsed time: #{readable_duration(elapsed_seconds)}. " \
            "#{current_rss_in_megabytes}. " \
            "Threads: #{threads_count}. " \
            "#{load_average}.\n\n" \
        end

        @last_elapsed_seconds = elapsed_seconds
      end

      def current_rss_in_megabytes
        rss_in_megabytes = OS.rss_bytes / 1024 / 1024

        "Current RSS: ~#{rss_in_megabytes.round}M"
      end

      def load_average
        if File.exist?('/proc/loadavg')
          "load average: #{File.read('/proc/loadavg')}"
        else
          `uptime`[/(load average:[^\n]+)/, 1] || '(uptime failed)'
        end
      end

      def threads_count
        Thread.list.size
      end
    end
  end
end

RSpec.configure do |config|
  config.add_formatter Support::RSpecRunTime::RSpecFormatter if ENV['GITLAB_CI']
end
