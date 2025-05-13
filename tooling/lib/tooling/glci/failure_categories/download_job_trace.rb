#!/usr/bin/env ruby
# frozen_string_literal: true

# To try out this class locally, use it as a script:
#
# ./tooling/lib/tooling/glci/failure_categories/download_job_trace.rb
#
# Locally, you'll need to set several ENV variables for this script to work:
#
# export CI_API_V4_URL="https://gitlab.com/api/v4"
# export CI_PROJECT_ID="278964"
# export CI_JOB_ID="8933045702"
# export PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE="${GITLAB_API_PRIVATE_TOKEN}"
# export CI_JOB_STATUS="failed"

require 'net/http'
require 'uri'

module Tooling
  module Glci
    module FailureCategories
      class DownloadJobTrace
        DEFAULT_TRACE_MARKER = 'failure-analyzer'
        DEFAULT_MAX_ATTEMPTS = 5
        DEFAULT_RETRY_DELAY_SECONDS = 10

        def initialize(
          api_url: ENV['CI_API_V4_URL'],
          project_id: ENV['CI_PROJECT_ID'],
          job_id: ENV['CI_JOB_ID'],
          access_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'],
          job_status: ENV['CI_JOB_STATUS'],
          trace_marker: DEFAULT_TRACE_MARKER,
          max_attempts: DEFAULT_MAX_ATTEMPTS,
          retry_delay: DEFAULT_RETRY_DELAY_SECONDS)
          @api_url = api_url
          @project_id = project_id
          @job_id = job_id
          @access_token = access_token
          @job_status = job_status
          @trace_marker = trace_marker
          @max_attempts = max_attempts
          @retry_delay = retry_delay

          validate_required_parameters!
        end

        def download(output_file: 'glci_job_trace.log')
          if @job_status != 'failed'
            puts "[DownloadJobTrace] Job did not fail: exiting early (status: #{@job_status})"
            return
          end

          trace_content = download_trace_with_retry
          return unless trace_content

          File.write(output_file, trace_content)
          puts "[DownloadJobTrace] Job trace saved to #{output_file}"

          output_file
        end

        private

        def download_trace_with_retry
          attempt = 0

          while attempt < @max_attempts
            attempt += 1
            puts "[DownloadJobTrace] Downloading job trace (attempt #{attempt}/#{@max_attempts})"

            trace_content = fetch_trace
            return trace_content if has_marker?(trace_content)

            sleep @retry_delay if attempt < @max_attempts
          end

          warn "[DownloadJobTrace] Could not verify we have the trace we need after #{@max_attempts} attempts"
          trace_content
        end

        def has_marker?(trace_content)
          return false if trace_content.nil? || trace_content.empty?

          has_marker = trace_content.match?(/#{@trace_marker}/)
          puts "[DownloadJobTrace] Trace marker #{has_marker ? 'found' : 'not found'}"

          has_marker
        end

        def fetch_trace
          uri = URI.parse("#{@api_url}/projects/#{@project_id}/jobs/#{@job_id}/trace")
          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = @access_token

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end

          unless response.is_a?(Net::HTTPSuccess)
            raise "[DownloadJobTrace] Failed to download job trace: #{response.code} #{response.message}"
          end

          response.body
        end

        def validate_required_parameters!
          missing_params = []
          missing_params << 'api_url' if @api_url.nil? || @api_url.empty?
          missing_params << 'project_id' if @project_id.nil? || @project_id.empty?
          missing_params << 'job_id' if @job_id.nil? || @job_id.empty?
          missing_params << 'access_token' if @access_token.nil? || @access_token.empty?
          missing_params << 'job_status' if @job_status.nil? || @job_status.empty?

          return if missing_params.empty?

          raise ArgumentError, "Missing required parameters: #{missing_params.join(', ')}"
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  downloader = Tooling::Glci::FailureCategories::DownloadJobTrace.new

  exit 1 unless downloader.download
end
