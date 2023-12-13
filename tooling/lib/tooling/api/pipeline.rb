# frozen_string_literal: true

require 'json'
require_relative 'request'
require_relative 'job'
require_relative '../debug'
require_relative '../../../../gems/gitlab-utils/lib/gitlab/utils/strong_memoize'

module Tooling
  module API
    class Pipeline
      include Tooling::Debug
      include Gitlab::Utils::StrongMemoize

      def initialize(api_token, project_id, pipeline_id)
        @api_token = api_token
        @project_id = project_id
        @pipeline_id = pipeline_id
      end

      def failed_jobs
        base_url = "https://gitlab.com/api/v4/projects/#{project_id}/pipelines/#{pipeline_id}/jobs"
        uri = URI("#{base_url}?scope[]=failed")

        jobs = []

        Request.get(api_token, uri) do |response|
          # rubocop:disable Gitlab/Json -- Avoid ActiveSupport
          jobs += JSON.parse(response.body)
          # rubocop:enable Gitlab/Json
        end

        jobs
      end
      strong_memoize_attr(:failed_jobs)

      def failed_spec_files
        print 'Fetching failed jobs... '
        puts "found #{failed_jobs.count}"

        rspec_failures = failed_jobs.flat_map do |job|
          job_id = job['id']

          puts "Fetching job logs for ##{job_id}"
          job = Job.new(api_token, project_id, job_id)

          rspec_failures = job.rspec_failed_files

          # Output progress.
          rspec_failures.each do |file|
            puts "  #{file}"
          end

          rspec_failures
        end

        rspec_failures.compact!
        rspec_failures.uniq!
        rspec_failures.sort!

        rspec_failures
      end

      private

      attr_reader :api_token, :project_id, :pipeline_id
    end
  end
end
