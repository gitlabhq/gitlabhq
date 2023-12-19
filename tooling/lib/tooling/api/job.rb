# frozen_string_literal: true

require 'pathname'

module Tooling
  module API
    class Job
      RSPEC_FILENAME_REGEX = /rspec '?([^\s:\[']+)[:\[]/

      def initialize(api_token, project_id, job_id)
        @api_token = api_token
        @project_id = project_id
        @job_id = job_id
      end

      def rspec_failed_files
        log = get_job_log
        extract_rspec_filenames(log)
      end

      private

      attr_reader :api_token, :project_id, :job_id

      def extract_rspec_filenames(log)
        log.scan(RSPEC_FILENAME_REGEX).map do |match|
          path = match[0]
          Pathname.new(path).relative_path_from('.').to_s
        end.uniq
      end

      def get_job_log
        uri = URI("https://gitlab.com/api/v4/projects/#{project_id}/jobs/#{job_id}/trace")
        response = Request.get(api_token, uri)

        response.body
      end
    end
  end
end
