# frozen_string_literal: true

require "logger"
require "json"

require_relative '../find_tests'
require_relative '../find_files_using_feature_flags'
require_relative '../mappings/graphql_base_type_mappings'
require_relative '../mappings/js_to_system_specs_mappings'
require_relative '../mappings/view_to_system_specs_mappings'
require_relative 'duo_system_spec_strategy'

module Tooling
  module PredictiveTests
    class TestSelector
      def initialize(
        changed_files:,
        rspec_test_mapping_path: nil,
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/450374#note_1836131381 on why limit might be used
        rspec_mappings_limit_percentage: 50,
        use_duo: false,
        git_diff_content: nil,
        logger: Logger.new($stdout, progname: "predictive test selector")
      )
        @changed_files = changed_files
        @rspec_test_mapping_path = rspec_test_mapping_path
        @rspec_mappings_limit_percentage = rspec_mappings_limit_percentage
        @use_duo = use_duo
        @git_diff_content = git_diff_content
        @logger = logger
      end

      # Predictive rspec test files specs list
      #
      # @return [Array]
      def rspec_spec_list
        logger.info "Creating predictive rspec test files specs list ..."
        logger.info "Changed files: #{changed_files.length}"

        specs = {
          test_file_finder_specs: specs_from_mapping,
          graphql_type_mapping_specs: specs_from_graphql_base_types,
          js_changes_specs: system_specs_from_js_changes,
          view_changes_specs: system_specs_from_view_changes
        }

        specs[:duo_system_specs] = duo_system_specs if use_duo

        # Calculate final unique list
        all_specs = specs.values.flatten
        unique_specs = all_specs.uniq

        logger.info "=" * 80
        logger.info "SUMMARY:"
        logger.info "  Total specs (with duplicates): #{all_specs.length}"
        logger.info "  Unique specs: #{unique_specs.length}"
        logger.info "  Duplicates removed: #{all_specs.length - unique_specs.length}"
        logger.info "=" * 80

        unique_specs
      end

      # Duo predicted system specs, only populated when use_duo is true
      #
      # @return [Array]
      def duo_spec_list
        return [] unless use_duo

        duo_system_specs
      end

      # Whether Duo made a confident prediction (as opposed to bailing out due to
      # low confidence, large diff, CLI failure, etc.)
      # Returns false if use_duo is disabled.
      #
      # @return [Boolean]
      def duo_confident?
        return false unless use_duo

        duo_system_specs # ensure strategy has been executed and @confident is set
        duo_system_spec_strategy.confident?
      end

      private

      attr_reader :changed_files,
        :rspec_test_mapping_path,
        :rspec_mappings_limit_percentage,
        :use_duo,
        :git_diff_content,
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

      # Memoized Duo strategy instance
      #
      # @return [DuoSystemSpecStrategy]
      def duo_system_spec_strategy
        @duo_system_spec_strategy ||= DuoSystemSpecStrategy.new(
          changed_files: changed_files,
          git_diff_content: @git_diff_content,
          logger: logger
        )
      end

      # Add system specs based on Duo AI analysis
      #
      # @return [Array]
      def duo_system_specs
        @duo_system_specs ||= duo_system_spec_strategy.execute
      end
    end
  end
end
