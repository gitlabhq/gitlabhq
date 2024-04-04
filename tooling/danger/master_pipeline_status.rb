# frozen_string_literal: true

require 'gitlab'

module Tooling
  module Danger
    module MasterPipelineStatus
      MASTER_PIPELINE_STATUS_PROJECT_ID = '40549124' # https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents
      MASTER_PIPELINE_STATUS_BRANCH = 'master-pipeline-status'
      MASTER_PIPELINE_STATUS_FILE_NAME = 'canonical-gitlab-master-pipeline-status.json'
      STATUS_PAGE_URL = 'https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/raw/master-pipeline-status/canonical-gitlab-master-pipeline-status.json'
      INCIDENT_TRACKER_URL = 'https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues'

      def check!
        return unless helper.ci?

        failed_master_pipeline_jobs = master_pipeline_jobs_statuses.select { |job| job['status'] == 'failed' }
        return if failed_master_pipeline_jobs.empty?

        pipeline_jobs = pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID'])
        return if pipeline_jobs.empty?

        job_statuses_to_warn = impacted_job_statuses(pipeline_jobs, failed_master_pipeline_jobs)
        warn(construct_message(job_statuses_to_warn)) if job_statuses_to_warn.any?
      end

      private

      def master_pipeline_jobs_statuses
        status_file_content = begin
          gitlab.api.file_contents(
            MASTER_PIPELINE_STATUS_PROJECT_ID,
            MASTER_PIPELINE_STATUS_FILE_NAME,
            MASTER_PIPELINE_STATUS_BRANCH
          )
        rescue StandardError
          '[]'
        end

        JSON.parse(status_file_content)
      rescue JSON::ParserError
        []
      end

      def pipeline_jobs(project_id, pipeline_id)
        gitlab.api.pipeline_jobs(project_id, pipeline_id).auto_paginate
      rescue StandardError
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

      def construct_message(job_statuses_to_warn)
        job_list = job_statuses_to_warn.map do |job|
          "* [#{job['name']}](#{job.dig('last_failed', 'web_url')})"
        end.join("\n")

        <<~MSG
          The [master pipeline status page](#{STATUS_PAGE_URL}) reported failures in

          #{job_list}

          If these jobs fail in your merge request with the same errors, then they are not caused by your changes.
          Please check for any on-going incidents in the [incident issue tracker](#{INCIDENT_TRACKER_URL}) or in the `#master-broken` Slack channel.
        MSG
      end
    end
  end
end
