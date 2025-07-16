# frozen_string_literal: true

require "logger"
require "json"

require_relative '../find_tests'
require_relative '../find_files_using_feature_flags'
require_relative '../mappings/graphql_base_type_mappings'
require_relative '../mappings/js_to_system_specs_mappings'
require_relative '../mappings/view_to_js_mappings'
require_relative '../mappings/view_to_system_specs_mappings'

# rubocop:disable Gitlab/Json -- not rails
module Tooling
  module PredictiveTests
    class TestSelector
      def initialize(
        changed_files:,
        rspec_test_mapping_path: nil,
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/450374#note_1836131381 on why limit might be used
        rspec_mappings_limit_percentage: 50,
        logger: Logger.new($stdout, progname: "predictive test selector")
      )
        @changed_files = changed_files
        @rspec_test_mapping_path = rspec_test_mapping_path
        @rspec_mappings_limit_percentage = rspec_mappings_limit_percentage
        @logger = logger
      end

      # Predictive rspec test files specs list
      #
      # @return [Array]
      def rspec_spec_list
        logger.info "Creating predictive rspec test files specs list ..."
        specs = {
          crystalball_mapping_specs: specs_from_mapping,
          graphql_type_mapping_specs: specs_from_graphql_base_types,
          js_changes_specs: system_specs_from_js_changes,
          view_changes_specs: system_specs_from_view_changes
        }

        logger.info("Generated following rspec specs list: #{JSON.pretty_generate(specs)}")
        specs.values.flatten
      end

      # Predictive js test files specs list
      #
      # @return [Array]
      def js_spec_list
        logger.info "Creating predictive js test files specs list ..."
        Tooling::Mappings::ViewToJsMappings.new(changed_files).execute.tap do |specs|
          logger.info "Generated following jest spec list: #{JSON.pretty_generate(specs)}"
        end
      end

      private

      attr_reader :changed_files,
        :rspec_test_mapping_path,
        :rspec_mappings_limit_percentage,
        :logger

      # Add specs based on crystalball mapping or static tests.yml file
      #
      # @return [void]
      def specs_from_mapping
        @specs_from_mapping ||= Tooling::FindTests.new(
          changed_files,
          mappings_file: rspec_test_mapping_path,
          mappings_limit_percentage: rspec_mappings_limit_percentage
        ).execute
      end

      # Add system specs based on changes to JS files.
      #
      # @return [void]
      def system_specs_from_js_changes
        @system_specs_from_js_changes ||= Tooling::Mappings::JsToSystemSpecsMappings.new(changed_files).execute
      end

      # Add specs based on potential changes to the GraphQL base types
      #
      # @return [void]
      def specs_from_graphql_base_types
        @specs_from_graphql_base_types ||= Tooling::Mappings::GraphqlBaseTypeMappings.new(changed_files).execute
      end

      # Add system specs based on changes to views.
      #
      # @return [void]
      def system_specs_from_view_changes
        @system_specs_from_view_changes ||= Tooling::Mappings::ViewToSystemSpecsMappings.new(changed_files).execute
      end
    end
  end
end
# rubocop:enable Gitlab/Json -- not rails
