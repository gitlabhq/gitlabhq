# frozen_string_literal: true

require "logger"
require "json"

require_relative '../find_tests'
require_relative '../find_files_using_feature_flags'
require_relative '../mappings/graphql_base_type_mappings'
require_relative '../mappings/js_to_system_specs_mappings'
require_relative '../mappings/view_to_js_mappings'
require_relative '../mappings/view_to_system_specs_mappings'

module Tooling
  module PredictiveTests
    class TestSelector
      def initialize(
        changed_files:,
        rspec_matching_test_files_path:,
        rspec_matching_js_files_path:,
        rspec_test_mapping_path: nil,
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/450374#note_1836131381 on why limit might be used
        rspec_mappings_limit_percentage: 50
      )
        @changed_files = changed_files
        @rspec_matching_test_files_path = rspec_matching_test_files_path
        @rspec_matching_js_files_path = rspec_matching_js_files_path
        @rspec_test_mapping_path = rspec_test_mapping_path
        @rspec_mappings_limit_percentage = rspec_mappings_limit_percentage
        @logger = Logger.new($stdout, progname: "predictive testing")
      end

      def execute
        logger.info(
          "Creating predictive test list based on following changed files: #{JSON.pretty_generate(changed_files)}" # rubocop:disable Gitlab/Json -- not rails
        )

        create_rspec_spec_list!
        create_js_spec_list!
      end

      private

      attr_reader :changed_files,
        :rspec_matching_test_files_path,
        :rspec_matching_js_files_path,
        :rspec_test_mapping_path,
        :rspec_mappings_limit_percentage,
        :logger

      # Create predictive rspec test files specs list
      #
      # @return [void]
      def create_rspec_spec_list!
        logger.info "Creating predictive rspec test files specs list ..."
        # TODO: Remove appending to file and work with arrays directly
        append_specs_from_mapping!
        append_specs_from_graphql_base_types!
        append_system_specs_from_js_changes!
        append_system_specs_from_view_changes!
      end

      # Create predictive js test files specs list
      #
      # @return [void]
      def create_js_spec_list!
        logger.info "Creating predictive js test files specs list ..."
        Tooling::Mappings::ViewToJsMappings.new(changed_files, rspec_matching_js_files_path).execute
      end

      # Create list of view files that include the potential rails partials
      #
      # @return [void]
      def create_view_partials_mapping_file!
        logger.info "Creating list of view files that include the potential rails partials ..."
        Tooling::Mappings::PartialToViewsMappings.new(changed_files, rspec_views_including_partials_path).execute
      end

      # Add specs based on crystalball mapping or static tests.yml file
      #
      # @return [void]
      def append_specs_from_mapping!
        Tooling::FindTests.new(
          changed_files,
          rspec_matching_test_files_path,
          mappings_file: rspec_test_mapping_path,
          mappings_limit_percentage: rspec_mappings_limit_percentage
        ).execute
      end

      # Add system specs based on changes to JS files.
      #
      # @return [void]
      def append_system_specs_from_js_changes!
        Tooling::Mappings::JsToSystemSpecsMappings.new(changed_files, rspec_matching_test_files_path).execute
      end

      # Add specs based on potential changes to the GraphQL base types
      #
      # @return [void]
      def append_specs_from_graphql_base_types!
        Tooling::Mappings::GraphqlBaseTypeMappings.new(changed_files, rspec_matching_test_files_path).execute
      end

      # Add system specs based on changes to views.
      #
      # @return [void]
      def append_system_specs_from_view_changes!
        Tooling::Mappings::ViewToSystemSpecsMappings.new(changed_files, rspec_matching_test_files_path).execute
      end
    end
  end
end
