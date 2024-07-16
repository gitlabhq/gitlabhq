# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require "net/http"
require "uri"

module Tooling
  module Danger
    module MasterPipelineStatus
      STATUS_FILE_PROJECT = 'https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents'
      STATUS_FILE_BRANCH = 'master-pipeline-status'
      STATUS_FILE_NAME = 'canonical-gitlab-master-pipeline-status.json'

      def check!
        return unless helper.ci? && applicable_mr?

        failed_master_pipeline_jobs = master_pipeline_jobs_statuses.select { |job| job['status'] == 'failed' }
        return if failed_master_pipeline_jobs.empty?

        pipeline_jobs = pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID'])
        return if pipeline_jobs.empty?

        job_statuses_to_warn = impacted_job_statuses(pipeline_jobs, failed_master_pipeline_jobs)
        warn(construct_message(job_statuses_to_warn)) if job_statuses_to_warn.any?
      end

      private

      def applicable_mr?
        helper.mr_target_branch == 'master' && ENV['CI_MERGE_REQUEST_EVENT_TYPE'] == 'merged_result'
      end

      def master_pipeline_jobs_statuses
        status_page_uri = URI(status_file_url)
        res = Net::HTTP.get_response(status_page_uri)

        unless res.is_a?(Net::HTTPSuccess)
          puts "Request to #{status_file_url} returned #{res.code} #{res.message}. Ignoring."
          return []
        end

        JSON.parse(res.body)
      rescue JSON::ParserError => e
        puts "Failed to parse JSON for #{status_file_url}. Ignoring. Full error:"
        puts e.message
        []
      end

      def pipeline_jobs(project_id, pipeline_id)
        gitlab.api.pipeline_jobs(project_id, pipeline_id).auto_paginate
      rescue StandardError => e
        puts "Failed to retrieve CI jobs via API for project #{project_id} and #{pipeline_id}: #{e.class}. Ignoring."
        []
      end

      def impacted_job_statuses(pipeline_jobs, failed_jobs_statuses)
        failed_jobs_statuses.select do |failed_job_status|
          pipeline_jobs.any? do |job|
            failed_job_status['name'] == job['name'] &&
              failed_job_status['stage'] == job['stage'] &&
              !job['allow_failure']
          end
        end
      end

      def status_file_url
        "#{STATUS_FILE_PROJECT}/-/raw/#{STATUS_FILE_BRANCH}/#{STATUS_FILE_NAME}"
      end

      def construct_message(job_statuses_to_warn)
        job_list = job_statuses_to_warn.map do |job|
          "* [#{job['name']}](#{job.dig('last_failed', 'web_url')})"
        end.join("\n")

        <<~MSG
          The [master pipeline status page](#{status_file_url}) reported failures in

          #{job_list}

          If these jobs fail in your merge request with the same errors, then they are not caused by your changes.
          Please check for any on-going incidents in the [incident issue tracker](#{STATUS_FILE_PROJECT}/-/issues) or in the `#master-broken` Slack channel.
        MSG
      end
    end
  end
end
