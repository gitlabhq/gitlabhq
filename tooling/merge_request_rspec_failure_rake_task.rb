# frozen_string_literal: true

require 'test_file_finder'
require_relative './merge_request'

module Tooling
  class MergeRequestRspecFailureRakeTask < RSpec::Core::RakeTask
    PROJECT_PATH = 'gitlab-org/gitlab'

    def run_task(_verbose)
      if pattern.empty?
        puts "No rspec failures in the merge request."
        return
      end

      super
    end

    def rspec_failures_on_merge_request
      test_file_finder = TestFileFinder::FileFinder.new
      test_file_finder.use TestFileFinder::MappingStrategies::GitlabMergeRequestRspecFailure.new(project_path: PROJECT_PATH, merge_request_iid: merge_request.iid)
      test_file_finder.test_files
    rescue TestFileFinder::TestReportError => e
      abort e.message
    end

    private

    def merge_request
      @merge_request ||= Tooling::MergeRequest.for(branch: current_branch, project_path: PROJECT_PATH)
    end

    def current_branch
      @current_branch ||= `git branch --show-current`.strip
    end
  end
end
