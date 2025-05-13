#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../events/track_pipeline_events'

# To try out this class locally, use it as a script:
#
# ./tooling/lib/tooling/glci/failure_categories/report_job_failure.rb
#
# Locally, you'll need to set several ENV variables for this script to work:
#
# export CI_JOB_ID="8933045702"
# export CI_INTERNAL_EVENTS_TOKEN="${GITLAB_API_PRIVATE_TOKEN}"

module Tooling
  module Glci
    module FailureCategories
      class ReportJobFailure
        def initialize(failure_category:, job_id: ENV['CI_JOB_ID'])
          @job_id = job_id
          @failure_category = failure_category
        end

        def report
          Tooling::Events::TrackPipelineEvents.new(
            event_name: "glci_job_failed",
            properties: {
              label: @job_id,
              property: @failure_category
            }
          ).send_event
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  reporter = Tooling::Glci::FailureCategories::ReportJobFailure.new(failure_category: 'local_test_failure_category')

  unless reporter.report
    warn "[ReportJobFailure] Error: Could not push the glci_job_failed internal event"
    exit 1
  end
end
