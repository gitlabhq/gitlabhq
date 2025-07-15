# frozen_string_literal: true

require 'tmpdir'

require_relative '../find_changes'
require_relative '../find_tests'
require_relative '../find_files_using_feature_flags'
require_relative '../mappings/graphql_base_type_mappings'
require_relative '../mappings/js_to_system_specs_mappings'
require_relative '../mappings/partial_to_views_mappings'
require_relative '../mappings/view_to_js_mappings'
require_relative '../mappings/view_to_system_specs_mappings'
require_relative '../events/track_pipeline_events'
require_relative '../helpers/file_handler'

module Tooling
  module PredictiveTests
    class TestSelector
      def initialize(
        frontend_fixtures_mapping_path:,
        rspec_matching_test_files_path:,
        rspec_views_including_partials_path:,
        rspec_matching_js_files_path:,
        rspec_changed_files_path:,
        rspec_test_mapping_path: nil,
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/450374#note_1836131381 on why limit might be used
        rspec_mappings_limit_percentage: 50
      )
        @rspec_matching_test_files_path = rspec_matching_test_files_path
        @rspec_views_including_partials_path = rspec_views_including_partials_path
        @frontend_fixtures_mapping_path = frontend_fixtures_mapping_path
        @rspec_matching_js_files_path = rspec_matching_js_files_path
        @rspec_test_mapping_path = rspec_test_mapping_path
        @rspec_mappings_limit_percentage = rspec_mappings_limit_percentage
        @rspec_changed_files_path = rspec_changed_files_path
      end

      def execute
        Tooling::FindChanges.new(
          from: :api,
          changed_files_pathname: rspec_changed_files_path
        ).execute

        find_tests(rspec_changed_files_path)
        find_tests(rspec_views_including_partials_path)

        Tooling::FindFilesUsingFeatureFlags.new(changed_files_pathname: rspec_changed_files_path).execute
        Tooling::Mappings::ViewToJsMappings.new(rspec_changed_files_path, rspec_matching_js_files_path).execute
        Tooling::Mappings::JsToSystemSpecsMappings.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
        Tooling::Mappings::GraphqlBaseTypeMappings.new(rspec_changed_files_path, rspec_matching_test_files_path).execute
        Tooling::Mappings::ViewToSystemSpecsMappings.new(rspec_changed_files_path,
          rspec_matching_test_files_path
        ).execute
        Tooling::Mappings::PartialToViewsMappings.new(
          rspec_changed_files_path,
          rspec_views_including_partials_path
        ).execute

        Tooling::FindChanges.new(
          from: :changed_files,
          changed_files_pathname: rspec_changed_files_path,
          predictive_tests_pathname: rspec_matching_test_files_path,
          frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_path
        ).execute
      end

      private

      attr_reader :rspec_matching_test_files_path,
        :rspec_views_including_partials_path,
        :frontend_fixtures_mapping_path,
        :rspec_matching_js_files_path,
        :rspec_changed_files_path,
        :rspec_test_mapping_path,
        :rspec_mappings_limit_percentage

      def find_tests(changed_files_pathname)
        Tooling::FindTests.new(
          changed_files_pathname,
          rspec_matching_test_files_path,
          mappings_file: rspec_test_mapping_path,
          mappings_limit_percentage: rspec_mappings_limit_percentage
        ).execute
      end
    end
  end
end
