#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require_relative 'helpers/predictive_tests_helper'

module Tooling
  class FindChanges
    include Helpers::PredictiveTestsHelper

    ALLOWED_FILE_TYPES = ['.js', '.vue', '.md', '.scss'].freeze

    def initialize(
      from:,
      changed_files_pathname: nil,
      predictive_tests_pathname: nil,
      frontend_fixtures_mapping_pathname: nil,
      file_filter: ->(_) { true },
      only_new_paths: false
    )

      raise ArgumentError, ':from can only be :api or :changed_files' unless
        %i[api changed_files].include?(from)

      @gitlab_endpoint = ENV['CI_API_V4_URL']

      @gitlab_token =
        if ENV['FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH']
          # We set FIND_CHANGES_API_TOKEN in the security FOSS project so it
          # can request the security EE project to retrieve the changed files.
          ENV['FIND_CHANGES_API_TOKEN']
        else
          ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
        end || ''

      @mr_project_path =
        ENV['FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH'] ||
        ENV['CI_MERGE_REQUEST_PROJECT_PATH']
      @mr_iid =
        ENV['FIND_CHANGES_MERGE_REQUEST_IID'] ||
        ENV['CI_MERGE_REQUEST_IID']

      @changed_files_pathname             = changed_files_pathname
      @predictive_tests_pathname          = predictive_tests_pathname
      @frontend_fixtures_mapping_pathname = frontend_fixtures_mapping_pathname
      @from                               = from
      @file_filter                        = file_filter
      @api_path_attributes                = only_new_paths ? %w[new_path] : %w[new_path old_path]
    end

    def execute
      if changed_files_pathname.nil?
        raise ArgumentError, "A path to the changed files file must be given as :changed_files_pathname"
      end

      case @from
      when :api
        write_array_to_file(changed_files_pathname, file_changes + frontend_fixture_files, append: false)
      else
        write_array_to_file(changed_files_pathname, frontend_fixture_files, append: true)
      end
    end

    def only_allowed_files_changed
      file_changes.any? && file_changes.all? { |file| ALLOWED_FILE_TYPES.include?(File.extname(file)) }
    end

    private

    attr_reader :gitlab_token, :gitlab_endpoint, :mr_project_path,
      :mr_iid, :changed_files_pathname, :predictive_tests_pathname,
      :frontend_fixtures_mapping_pathname, :file_filter, :api_path_attributes

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

    def frontend_fixture_files
      # If we have a `test file -> JSON frontend fixture` mapping file, we add the files JSON frontend fixtures
      # files to the list of changed files so that Jest can automatically run the dependent tests
      # using --findRelatedTests flag.
      empty = [].freeze

      test_files.flat_map do |test_file|
        frontend_fixtures_mapping[test_file] || empty
      end
    end

    def file_changes
      @file_changes ||=
        case @from
        when :api
          mr_changes.changes.select(&file_filter).flat_map do |change|
            change.to_h.values_at(*api_path_attributes)
          end.uniq
        else
          read_array_from_file(changed_files_pathname)
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
