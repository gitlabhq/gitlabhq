#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require_relative 'helpers/predictive_tests_helper'

module Tooling
  class FindChanges
    include Helpers::PredictiveTestsHelper

    def initialize(
      from:,
      changed_files_pathname: nil,
      predictive_tests_pathname: nil,
      frontend_fixtures_mapping_pathname: nil
    )

      raise ArgumentError, ':from can only be :api or :changed_files' unless
        %i[api changed_files].include?(from)

      @gitlab_token                       = ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'] || ''
      @gitlab_endpoint                    = ENV['CI_API_V4_URL']
      @mr_project_path                    = ENV['CI_MERGE_REQUEST_PROJECT_PATH']
      @mr_iid                             = ENV['CI_MERGE_REQUEST_IID']
      @changed_files_pathname             = changed_files_pathname
      @predictive_tests_pathname          = predictive_tests_pathname
      @frontend_fixtures_mapping_pathname = frontend_fixtures_mapping_pathname
      @from                               = from
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

    def only_js_files_changed
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
          mr_changes.changes.flat_map do |change|
            change.to_h.values_at('old_path', 'new_path')
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
