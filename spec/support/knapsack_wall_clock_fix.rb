# frozen_string_literal: true

require 'rspec/core/formatters/base_formatter'

module Support
  # Overwrites knapsack's per-file durations with wall-clock time.
  # Knapsack stops its timer in append_after(:context), missing expensive teardown
  # hooks (e.g. ensure_schema_and_empty_tables for migration specs) that run after.
  # Formatter events fire after all hooks, so they capture the full duration.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/591886
  class KnapsackWallClockFix < RSpec::Core::Formatters::BaseFormatter
    RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished

    def start(_notification)
      @group_level = 0
      # Wall-clock time this formatter has measured per file so far this run. A file
      # can have several top-level describe blocks; we sum their wall-clock durations
      # here and always write this total, rather than reading back knapsack's value.
      @wall_clock_time_per_file = Hash.new(0.0)
    end

    def example_group_started(_notification)
      @current_group_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) if @group_level == 0
      @group_level += 1
    end

    def example_group_finished(notification)
      @group_level -= 1 if @group_level > 0

      # Skip nested describe/context blocks; only record at file-level scope.
      return unless @group_level == 0

      file_path = notification.group.metadata[:file_path].sub('./', '')
      wall_clock_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @current_group_start_time
      @wall_clock_time_per_file[file_path] += wall_clock_duration

      # Overwrite knapsack's per-file duration with our own wall-clock total so
      # Report#save writes corrected values. We always assign (never read back
      # knapsack's value), because knapsack's Tracker#stop_timer also accumulates
      # into this hash for every top-level group; adding to it would double-count.
      Knapsack.tracker.test_files_with_time[file_path] = @wall_clock_time_per_file[file_path]
    end
  end
end

RSpec.configure do |config|
  config.add_formatter Support::KnapsackWallClockFix if ENV['KNAPSACK_GENERATE_REPORT']
end
