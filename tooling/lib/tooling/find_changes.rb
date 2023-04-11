#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require_relative 'helpers/file_handler'

module Tooling
  class FindChanges
    include Helpers::FileHandler

    def initialize(
      changed_files_pathname = nil, predictive_tests_pathname = nil, frontend_fixtures_mapping_pathname = nil
    )
      @gitlab_token                       = ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'] || ''
      @gitlab_endpoint                    = ENV['CI_API_V4_URL']
      @mr_project_path                    = ENV['CI_MERGE_REQUEST_PROJECT_PATH']
      @mr_iid                             = ENV['CI_MERGE_REQUEST_IID']
      @changed_files_pathname             = changed_files_pathname
      @predictive_tests_pathname          = predictive_tests_pathname
      @frontend_fixtures_mapping_pathname = frontend_fixtures_mapping_pathname
    end

    def execute
      if changed_files_pathname.nil?
        raise ArgumentError, "A path to the changed files file must be given as first argument."
      end

      add_frontend_fixture_files!
      write_array_to_file(changed_files_pathname, file_changes, overwrite: true)
    end

    def only_js_files_changed
      @changed_files_pathname = nil # We ensure that we'll get the diff from the MR directly, not from a file.

      file_changes.any? && file_changes.all? { |file| file.end_with?('.js') }
    end

    private

    attr_reader :gitlab_token, :gitlab_endpoint, :mr_project_path,
      :mr_iid, :changed_files_pathname, :predictive_tests_pathname, :frontend_fixtures_mapping_pathname

    def gitlab
      @gitlab ||= begin
        Gitlab.configure do |config|
          config.endpoint      = gitlab_endpoint
          config.private_token = gitlab_token
        end

        Gitlab
      end
    end

    def add_frontend_fixture_files?
      predictive_tests_pathname && frontend_fixtures_mapping_pathname
    end

    def add_frontend_fixture_files!
      return unless add_frontend_fixture_files?

      # If we have a `test file -> JSON frontend fixture` mapping file, we add the files JSON frontend fixtures
      # files to the list of changed files so that Jest can automatically run the dependent tests
      # using --findRelatedTests flag.
      test_files.each do |test_file|
        file_changes.concat(frontend_fixtures_mapping[test_file]) if frontend_fixtures_mapping.key?(test_file)
      end
    end

    def file_changes
      @file_changes ||=
        if changed_files_pathname && File.exist?(changed_files_pathname)
          read_array_from_file(changed_files_pathname)
        else
          mr_changes.changes.flat_map do |change|
            change.to_h.values_at('old_path', 'new_path')
          end.uniq
        end
    end

    def mr_changes
      @mr_changes ||= gitlab.merge_request_changes(mr_project_path, mr_iid)
    end

    def test_files
      return [] if !predictive_tests_pathname || !File.exist?(predictive_tests_pathname)

      read_array_from_file(predictive_tests_pathname)
    end

    def frontend_fixtures_mapping
      return {} if !frontend_fixtures_mapping_pathname || !File.exist?(frontend_fixtures_mapping_pathname)

      JSON.parse(File.read(frontend_fixtures_mapping_pathname)) # rubocop:disable Gitlab/Json
    end
  end
end
