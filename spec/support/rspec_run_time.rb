# frozen_string_literal: true

require 'yaml'
require 'rspec/core/formatters/base_formatter'
require_relative '../../tooling/lib/tooling/helpers/duration_formatter'

module Support
  module RSpecRunTime
    class RSpecFormatter < RSpec::Core::Formatters::BaseFormatter
      include Tooling::Helpers::DurationFormatter

      RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished

      def start(_notification)
        @group_level = 0
        @rspec_test_suite_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        output.puts "\n# Starting RSpec timer..."
      end

      def example_group_started(_notification)
        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) if @group_level == 0
        @group_level += 1
      end

      def example_group_finished(notification)
        @group_level -= 1 if @group_level > 0
        return unless @group_level == 0

        time_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = time_now - @start_time
        elapsed_time = time_now - @rspec_test_suite_start_time

        output.puts "\nExample group #{notification.group.description} took #{readable_duration(duration)}."
        output.puts "\nRSpec timer is at #{time_now}. RSpec elapsed time: #{readable_duration(elapsed_time)}.\n\n"
      end
    end
  end
end

RSpec.configure do |config|
  config.add_formatter Support::RSpecRunTime::RSpecFormatter if ENV['GITLAB_CI']
end
