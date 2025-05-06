#!/usr/bin/env ruby
# frozen_string_literal: true

# To try out this class locally, use it as a script:
#
# ./tooling/lib/tooling/glci/failure_categories/job_trace_to_failure_category.rb <job_trace_file>
# Example: ./tooling/lib/tooling/glci/failure_categories/job_trace_to_failure_category.rb glci_job_trace.log

require 'fileutils'
require 'pathname'
require 'yaml'

module Tooling
  module Glci
    module FailureCategories
      class JobTraceToFailureCategory
        PATTERNS_DIR = File.expand_path('patterns', __dir__)

        def initialize
          @patterns = load_patterns_from_file('single_line_patterns.yml')
          @multiline_patterns = load_patterns_from_file('multiline_patterns.yml')
          @catchall_patterns = load_patterns_from_file('catchall_patterns.yml')
        end

        # Analyzes a job trace file to determine the failure category based on pattern matching.
        #
        # This method examines the content of a job trace file against three sets of patterns
        # (regular patterns, multiline patterns, and catchall patterns) to categorize the type
        # of failure that occurred.
        #
        # @param job_trace [String] Path to the job trace file to analyze
        #
        # @return [Hash] A pattern info hash containing category information if a match is found,
        #                or an empty hash if no match is found or if the trace file is invalid
        def process(job_trace)
          if !job_trace || !File.exist?(job_trace) || File.empty?(job_trace)
            warn "[JobTraceToFailureCategory] Error: Missing job trace file, or empty"
            return {}
          end

          trace = File.read(job_trace)

          patterns.each do |pattern_info|
            return pattern_info if trace.match?(/#{pattern_info[:pattern]}/i)
          end

          multiline_patterns.each do |pattern_info|
            first_pattern, second_pattern = pattern_info[:pattern].split(',')
            return pattern_info if trace.match?(/#{first_pattern}/i) && trace.match?(/#{second_pattern}/i)
          end

          catchall_patterns.each do |pattern_info|
            return pattern_info if trace.match?(/#{pattern_info[:pattern]}/i)
          end

          warn "[JobTraceToFailureCategory] Error: Could not find any failure category"

          {}
        end

        private

        attr_accessor :patterns, :multiline_patterns, :catchall_patterns

        def load_patterns_from_file(filename)
          yaml_data = YAML.safe_load_file(File.join(PATTERNS_DIR, filename), permitted_classes: [Symbol])
          result = []

          categories = yaml_data.each_value.first

          categories.each do |category_name, category_data|
            category_data['patterns'].each do |pattern|
              result << { pattern: pattern, failure_category: category_name.to_s }
            end
          end

          result
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    warn "[JobTraceToFailureCategory] Error: Missing job trace file"
    warn "Usage: #{$PROGRAM_NAME} <job_trace_file>"
    warn "Example: #{$PROGRAM_NAME} /path/to/job_trace.log"
    exit 1
  end

  failure_category_hash = Tooling::Glci::FailureCategories::JobTraceToFailureCategory.new.process(ARGV[0])
  exit 1 if failure_category_hash.empty?

  puts failure_category_hash[:failure_category]
end
