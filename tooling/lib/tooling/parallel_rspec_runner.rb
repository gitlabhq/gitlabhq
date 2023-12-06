# frozen_string_literal: true

require 'knapsack'
require 'fileutils'
require 'json'
require_relative './helpers/duration_formatter'

module Knapsack
  module Distributors
    class BaseDistributor
      # Refine https://github.com/KnapsackPro/knapsack/blob/v1.21.1/lib/knapsack/distributors/base_distributor.rb
      # to take in account the additional filtering we do for predictive jobs.
      module BaseDistributorWithTestFiltering
        attr_reader :filter_tests

        def initialize(args = {})
          super

          @filter_tests = args[:filter_tests]
        end

        def all_tests
          @all_tests ||= begin
            pattern_tests = Dir.glob(test_file_pattern).uniq

            if filter_tests.empty?
              pattern_tests
            else
              pattern_tests & filter_tests
            end
          end.sort
        end
      end

      prepend BaseDistributorWithTestFiltering
    end
  end

  class AllocatorBuilder
    # Refine https://github.com/KnapsackPro/knapsack/blob/v1.21.1/lib/knapsack/allocator_builder.rb
    # to take in account the additional filtering we do for predictive jobs.
    module AllocatorBuilderWithTestFiltering
      attr_accessor :filter_tests

      def allocator
        Knapsack::Allocator.new({
          report: Knapsack.report.open,
          test_file_pattern: test_file_pattern,
          ci_node_total: Knapsack::Config::Env.ci_node_total,
          ci_node_index: Knapsack::Config::Env.ci_node_index,
          # Additional argument
          filter_tests: filter_tests
        })
      end
    end

    prepend AllocatorBuilderWithTestFiltering
  end
end

# A custom parallel rspec runner based on Knapsack runner
# which takes in additional option for a file containing
# list of test files.
#
# When executing RSpec in CI, the list of tests allocated by Knapsack
# will be compared with the test files listed in the file.
#
# Only the test files allocated by Knapsack and listed in the file
# would be executed in the CI node.
#
# Reference:
# https://github.com/ArturT/knapsack/blob/v1.21.1/lib/knapsack/runners/rspec_runner.rb
module Tooling
  class ParallelRSpecRunner
    include Tooling::Helpers::DurationFormatter

    # rubocop:disable Gitlab/Json -- standard JSON is sufficient
    def self.run(rspec_args: nil, filter_tests_file: nil)
      new(rspec_args: rspec_args, filter_tests_file: filter_tests_file).run
    end

    def initialize(filter_tests_file: nil, rspec_args: nil)
      @filter_tests_file = filter_tests_file
      @rspec_args = rspec_args&.split(' ') || []
    end

    def run
      if ENV['GITLAB_CI'] && ENV['KNAPSACK_RSPEC_SUITE_REPORT_PATH']
        expected_duration_report = parse_expected_duration_from_master_report
        knapsack_dir = File.dirname(ENV['KNAPSACK_RSPEC_SUITE_REPORT_PATH'])
        FileUtils.mkdir_p(knapsack_dir)
        File.write(File.join(knapsack_dir, 'node_specs_expected_duration.json'), JSON.dump(expected_duration_report))

        Knapsack.logger.info "Expected duration for tests:\n\n"
        Knapsack.logger.info "#{JSON.pretty_generate(expected_duration_report)}\n\n"
      end

      if node_tests.empty?
        Knapsack.logger.info 'No tests to run on this node, exiting.'
        return
      end

      Knapsack.logger.info "Running command: #{rspec_command.join(' ')}"

      exec(*rspec_command)
    end

    private

    attr_reader :filter_tests_file, :rspec_args

    def parse_expected_duration_from_master_report
      master_report = JSON.parse(File.read(ENV['KNAPSACK_RSPEC_SUITE_REPORT_PATH']))
      return unless master_report

      Knapsack.logger.info "Parsing expected rspec suite duration..."
      duration_total = 0

      expected_duration_report = {}

      node_tests.each do |file|
        if master_report[file]
          duration_total += master_report[file]
          expected_duration_report[file] = master_report[file]
        else
          Knapsack.logger.info "#{file} not found in master report"
        end
      end

      Knapsack.logger.info "RSpec suite is expected to take #{readable_duration(duration_total)}."

      expected_duration_report
    end

    def rspec_command
      %w[bundle exec rspec].tap do |cmd|
        cmd.push(*rspec_args)
        cmd.push('--')
        cmd.push(*node_tests)
      end
    end

    def node_tests
      allocator.node_tests
    end

    def filter_tests
      @filter_tests ||=
        filter_tests_file ? tests_from_file(filter_tests_file) : []
    end

    def tests_from_file(filter_tests_file)
      return [] unless File.exist?(filter_tests_file)

      File.read(filter_tests_file).split(' ')
    end

    def allocator
      @allocator ||=
        Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).tap do |builder|
          builder.filter_tests = filter_tests
        end.allocator
    end
    # rubocop:enable Gitlab/Json
  end
end
