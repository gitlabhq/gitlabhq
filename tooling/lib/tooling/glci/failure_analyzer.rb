#!/usr/bin/env ruby
# frozen_string_literal: true

# To try out this class locally, use it as a script:
#
# ./tooling/lib/tooling/glci/failure_analyzer.rb
#
# You'll have to follow the instructions for the individual classes we're calling.

require_relative 'failure_categories/download_job_trace'
require_relative 'failure_categories/job_trace_to_failure_category'
require_relative 'failure_categories/report_job_failure'

module Tooling
  module Glci
    # FailureAnalyzer coordinates the CI job failure analysis process.
    #
    # This class serves as an orchestrator that coordinates the three main steps
    # of CI job failure analysis:
    # 1. Downloading the CI job trace
    # 2. Analyzing the trace to determine the failure category
    # 3. Reporting the failure category via internal events
    #
    # The orchestrator relies on environment variables that are typically available
    # in GitLab CI/CD jobs for operation.
    class FailureAnalyzer
      def analyze_job(job_id)
        trace_path = Tooling::Glci::FailureCategories::DownloadJobTrace.new.download

        unless trace_path
          warn "[GCLI Failure Analyzer] Missing job trace. Exiting."
          return {}
        end

        failure_category_hash = Tooling::Glci::FailureCategories::JobTraceToFailureCategory.new.process(trace_path)
        if failure_category_hash.empty?
          warn "[GCLI Failure Analyzer] Missing failure category. Exiting."
          return {}
        end

        Tooling::Glci::FailureCategories::ReportJobFailure.new(
          job_id: job_id,
          failure_category: failure_category_hash[:failure_category]
        ).report

        failure_category_hash
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    warn "[GCLI Failure Analyzer] Error: Missing job ID"
    warn "Usage: #{$PROGRAM_NAME} <job_id>"
    warn "Example: #{$PROGRAM_NAME} 12345"
    exit 1
  end

  job_id = ARGV[0]
  begin
    failure_analyzer = Tooling::Glci::FailureAnalyzer.new

    failure_category_hash = failure_analyzer.analyze_job(job_id)
    if failure_category_hash.empty?
      puts "[GCLI Failure Analyzer] Did not find a failure category for job ##{job_id}."
    else
      puts "[GCLI Failure Analyzer] Job ##{job_id} categorized as: " \
        "#{failure_category_hash[:failure_category]} (matching pattern: \"#{failure_category_hash[:pattern]}\")"
    end
  rescue StandardError => e
    warn "[GCLI Failure Analyzer] Error: #{e.message} #{e.backtrace}"
    exit 1
  end
end
