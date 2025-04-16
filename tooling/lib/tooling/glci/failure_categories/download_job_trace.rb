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
        def initialize(
          api_url: ENV['CI_API_V4_URL'],
          project_id: ENV['CI_PROJECT_ID'],
          job_id: ENV['CI_JOB_ID'],
          access_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'],
          job_status: ENV['CI_JOB_STATUS'])
          @api_url    = api_url
          @project_id = project_id
          @job_id     = job_id
          @access_token = access_token
          @job_status = job_status

          validate_required_parameters!
        end

        def download(output_file: 'glci_job_trace.log')
          if @job_status != 'failed'
            puts "[DownloadJobTrace] Job did not fail: exiting early (status: #{@job_status})"
            return
          end

          uri = URI.parse("#{@api_url}/projects/#{@project_id}/jobs/#{@job_id}/trace")
          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = @access_token

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end

          unless response.is_a?(Net::HTTPSuccess)
            raise "[DownloadJobTrace] Failed to download job trace: #{response.code} #{response.message}"
          end

          File.write(output_file, response.body)

          output_file
        end

        private

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
