# frozen_string_literal: true

require 'knapsack'

module KnapsackRefinements
  # Refine https://github.com/KnapsackPro/knapsack/blob/v1.21.1/lib/knapsack/distributors/base_distributor.rb
  # to take in account the additional filtering we do for predictive jobs.
  refine ::Knapsack::Distributors::BaseDistributor do
    attr_reader :filter_tests

    def initialize(args = {})
      super

      @filter_tests = args[:filter_tests]
    end

    def all_tests
      @all_tests ||= begin
        pattern_tests = Dir.glob(test_file_pattern).uniq

        if filter_tests.empty?
          Knapsack.logger.info 'Running all node tests without filter'
          pattern_tests
        else
          pattern_tests & filter_tests
        end
      end.sort
    end
  end

  # Refine https://github.com/KnapsackPro/knapsack/blob/v1.21.1/lib/knapsack/allocator_builder.rb
  # to take in account the additional filtering we do for predictive jobs.
  refine ::Knapsack::AllocatorBuilder do
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
end

using KnapsackRefinements

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
    def self.run(rspec_args: nil, filter_tests_file: nil)
      new(rspec_args: rspec_args, filter_tests_file: filter_tests_file).run
    end

    def initialize(allocator: knapsack_allocator, filter_tests_file: nil, rspec_args: nil)
      @allocator = allocator
      @filter_tests_file = filter_tests_file
      @rspec_args = rspec_args&.split(' ') || []
    end

    def run
      Knapsack.logger.info
      Knapsack.logger.info 'Filter specs:'
      Knapsack.logger.info filter_tests
      Knapsack.logger.info
      Knapsack.logger.info 'Running specs:'
      Knapsack.logger.info node_tests
      Knapsack.logger.info

      if node_tests.empty?
        Knapsack.logger.info 'No tests to run on this node, exiting.'
        return
      end

      Knapsack.logger.info "Running command: #{rspec_command.join(' ')}"

      exec(*rspec_command)
    end

    private

    attr_reader :allocator, :filter_tests_file, :rspec_args

    def rspec_command
      %w[bundle exec rspec].tap do |cmd|
        cmd.push(*rspec_args)
        cmd.push('--default-path', allocator.test_dir)
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

    def knapsack_allocator
      Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).tap do |builder|
        builder.filter_tests = filter_tests
      end.allocator
    end
  end
end
