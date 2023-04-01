#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'

module Tooling
  class FindChanges
    def initialize(output_file: nil, matched_tests_file: nil, frontend_fixtures_mapping_path: nil)
      @gitlab_token                   = ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'] || ''
      @gitlab_endpoint                = ENV['CI_API_V4_URL']
      @mr_project_path                = ENV['CI_MERGE_REQUEST_PROJECT_PATH']
      @mr_iid                         = ENV['CI_MERGE_REQUEST_IID']
      @output_file                    = output_file
      @matched_tests_file             = matched_tests_file
      @frontend_fixtures_mapping_path = frontend_fixtures_mapping_path
    end

    def execute
      raise ArgumentError, "An path to an output file must be given as first argument." if output_file.nil?

      add_frontend_fixture_files!
      File.write(output_file, file_changes.join(' '))
    end

    def only_js_files_changed
      @output_file = nil # We ensure that we'll get the diff from the MR directly, not from a file.

      file_changes.any? && file_changes.all? { |file| file.end_with?('.js') }
    end

    private

    attr_reader :gitlab_token, :gitlab_endpoint, :mr_project_path,
      :mr_iid, :output_file, :matched_tests_file, :frontend_fixtures_mapping_path

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
      matched_tests_file && frontend_fixtures_mapping_path
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
        if output_file && File.exist?(output_file)
          File.read(output_file).split(' ')
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
      return [] if !matched_tests_file || !File.exist?(matched_tests_file)

      File.read(matched_tests_file).split(' ')
    end

    def frontend_fixtures_mapping
      return {} if !frontend_fixtures_mapping_path || !File.exist?(frontend_fixtures_mapping_path)

      JSON.parse(File.read(frontend_fixtures_mapping_path)) # rubocop:disable Gitlab/Json
    end
  end
end
