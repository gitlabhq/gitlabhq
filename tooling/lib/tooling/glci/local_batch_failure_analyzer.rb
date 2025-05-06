#!/usr/bin/env ruby
# frozen_string_literal: true

# To try out this class locally, use it as a script:
#
# ./tooling/lib/tooling/glci/local_batch_failure_analyzer.rb [job_url | --csv file.csv]
#
# Example usage:
# Single job: ./tooling/lib/tooling/glci/local_batch_failure_analyzer.rb https://gitlab.com/gitlab-org/gitlab/-/jobs/12345
# Batch mode: ./tooling/lib/tooling/glci/local_batch_failure_analyzer.rb --csv jobs.csv
#
# jobs.csv content example:
# CREATED_AT,JOB_URL
# 2025-04-30T00:29:26.195478Z,https://gitlab.com/gitlab-org/gitlab/-/jobs/12345
# 2025-04-30T00:29:26.04171Z,https://gitlab.com/gitlab-org/gitlab/-/jobs/12346
#
# Pro-tip:
#
# Add this alias to your .bashrc/.zshrc to have the fca (failure category analyzer) available in your shell!
# (the alias should be on a single line)
#
# alias fca='PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE="${GITLAB_API_PRIVATE_TOKEN}"
#            ~/src/gdk/gitlab/tooling/lib/tooling/glci/local_batch_failure_analyzer.rb'

require 'csv'
require 'optparse'
require 'uri'
require_relative 'failure_analyzer'

module Tooling
  module Glci
    # LocalBatchFailureAnalyzer extends the functionality of FailureAnalyzer
    # to support batch processing of job URLs from either command line arguments
    # or a CSV file, without reporting the results via internal events.
    #
    # This class is designed for local analysis and debugging purposes.
    class LocalBatchFailureAnalyzer
      # Extracts job ID from a GitLab CI job URL
      # @param job_url [String] URL of the GitLab CI job
      # @return [String, nil] Job ID if found, nil otherwise
      def extract_job_id_from_url(job_url)
        return unless job_url

        return ::Regexp.last_match(1) if job_url =~ %r{/jobs/(\d+)(?:/|\z)}

        job_url.split('/').last
      rescue StandardError => e
        warn "[Local Batch Failure Analyzer] Error extracting job ID from URL: #{job_url} - #{e.message}"
      end

      # Extracts project ID from a GitLab CI job URL
      # @param job_url [String] URL of the GitLab CI job
      # @return [String, nil] Project ID if found, nil otherwise
      def extract_project_id_from_url(job_url)
        return unless job_url

        ::Regexp.last_match(1) if job_url =~ %r{gitlab\.com/([-\w]+/[-\w]+)}
      rescue StandardError => e
        warn "[Local Batch Failure Analyzer] Error extracting project ID from URL: #{job_url} - #{e.message}"
      end

      # Analyzes a single job without reporting
      # @param job_url [String] URL of the GitLab CI job
      # @return [String, nil] Failure category if found, nil otherwise
      def analyze_single_job(job_url)
        job_id = extract_job_id_from_url(job_url)
        project_path = extract_project_id_from_url(job_url)

        unless job_id && project_path
          warn "[Local Batch Failure Analyzer] Could not extract job ID or project ID from URL: #{job_url}"
          return
        end

        project_id = URI.encode_www_form_component(project_path)

        # Set those variables, as they are required by the ruby classes we'll call.
        ENV['CI_API_V4_URL'] = 'https://gitlab.com/api/v4'
        ENV['CI_PROJECT_ID'] = project_id
        ENV['CI_JOB_ID'] = job_id
        ENV['CI_JOB_STATUS'] = 'failed'

        unless ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
          warn "[Local Batch Failure Analyzer] Error: PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE is not set"
          warn "Please set it using: PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE=your_token #{$PROGRAM_NAME} ..."
          return
        end

        begin
          trace_path = Tooling::Glci::FailureCategories::DownloadJobTrace.new.download
          return unless trace_path

          failure_category_hash = Tooling::Glci::FailureCategories::JobTraceToFailureCategory.new.process(trace_path)
          return if failure_category_hash.empty?

          puts "[Local Batch Failure Analyzer] Job ##{job_id} categorized as: " \
            "#{failure_category_hash[:failure_category]} (matching pattern: \"#{failure_category_hash[:pattern]}\")"
        rescue StandardError => e
          warn "[Local Batch Failure Analyzer] Error: #{e}"
          nil
        end
      end

      # Analyzes multiple jobs from a CSV file
      # @param csv_path [String] Path to the CSV file containing job URLs
      # @return [Hash] Job URLs mapped to their failure categories
      def analyze_jobs_from_csv(csv_path)
        unless File.exist?(csv_path)
          warn "[Local Batch Failure Analyzer] CSV file not found: #{csv_path}"
          return {}
        end

        results = {}

        begin
          job_urls = CSV.read(csv_path, headers: true).filter_map { |row| row['JOB_URL'] }
          job_urls.each do |job_url|
            failure_category = analyze_single_job(job_url)
            results[job_url] = failure_category if failure_category
          end
        rescue StandardError => e
          warn "[Local Batch Failure Analyzer] Error: #{e.message}"
        end

        results
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options] [JOB_URL]"
    opts.separator ""
    opts.separator "You must provide either a job URL as an argument or use the --csv option."

    opts.on("--csv FILE", "Process multiple jobs from a CSV file") do |file|
      options[:csv] = file
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
  rescue OptionParser::MissingArgument => e
    warn "[Local Batch Failure Analyzer] Error: #{e.message}"
    puts parser
    exit 1
  end

  job_url = ARGV[0]
  if !options[:csv] && !job_url
    warn "[Local Batch Failure Analyzer] Error: Missing job URL or CSV file path"
    puts parser
    exit 1
  end

  analyzer = Tooling::Glci::LocalBatchFailureAnalyzer.new

  if options[:csv]
    analyzer.analyze_jobs_from_csv(options[:csv])
  elsif job_url
    analyzer.analyze_single_job(job_url)
  end
end
