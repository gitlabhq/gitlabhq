# frozen_string_literal: true

require 'knapsack'

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
# https://github.com/ArturT/knapsack/blob/v1.20.0/lib/knapsack/runners/rspec_runner.rb
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
      Knapsack.logger.info 'Knapsack node specs:'
      Knapsack.logger.info node_tests
      Knapsack.logger.info
      Knapsack.logger.info 'Filter specs:'
      Knapsack.logger.info filter_tests
      Knapsack.logger.info
      Knapsack.logger.info 'Running specs:'
      Knapsack.logger.info tests_to_run
      Knapsack.logger.info

      if tests_to_run.empty?
        Knapsack.logger.info 'No tests to run on this node, exiting.'
        return
      end

      exec(*rspec_command)
    end

    private

    attr_reader :allocator, :filter_tests_file, :rspec_args

    def rspec_command
      %w[bundle exec rspec].tap do |cmd|
        cmd.push(*rspec_args)
        cmd.push('--default-path', allocator.test_dir)
        cmd.push('--')
        cmd.push(*tests_to_run)
      end
    end

    def tests_to_run
      if filter_tests.empty?
        Knapsack.logger.info 'Running all node tests without filter'
        return node_tests
      end

      @tests_to_run ||= node_tests & filter_tests
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
      Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator
    end
  end
end
