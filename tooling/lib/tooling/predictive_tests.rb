# frozen_string_literal: true

require_relative 'find_changes'
require_relative 'find_tests'
require_relative 'find_files_using_feature_flags'
require_relative 'mappings/graphql_base_type_mappings'
require_relative 'mappings/js_to_system_specs_mappings'
require_relative 'mappings/partial_to_views_mappings'
require_relative 'mappings/view_to_js_mappings'
require_relative 'mappings/view_to_system_specs_mappings'

module Tooling
  class PredictiveTests
    REQUIRED_ENV_VARIABLES = %w[
      RSPEC_CHANGED_FILES_PATH
      RSPEC_MATCHING_TESTS_PATH
      RSPEC_VIEWS_INCLUDING_PARTIALS_PATH
      FRONTEND_FIXTURES_MAPPING_PATH
      RSPEC_MATCHING_JS_FILES_PATH
    ].freeze

    def initialize
      missing_env_variables = REQUIRED_ENV_VARIABLES.select { |key| ENV[key.to_s] == '' }
      unless missing_env_variables.empty?
        raise "[predictive tests] Missing ENV variable(s): #{missing_env_variables.join(',')}."
      end

      @rspec_changed_files_path            = ENV['RSPEC_CHANGED_FILES_PATH']
      @rspec_matching_tests_path           = ENV['RSPEC_MATCHING_TESTS_PATH']
      @rspec_views_including_partials_path = ENV['RSPEC_VIEWS_INCLUDING_PARTIALS_PATH']
      @frontend_fixtures_mapping_path      = ENV['FRONTEND_FIXTURES_MAPPING_PATH']
      @rspec_matching_js_files_path        = ENV['RSPEC_MATCHING_JS_FILES_PATH']
    end

    def execute
      Tooling::FindChanges.new(
        from: :api,
        changed_files_pathname: rspec_changed_files_path
      ).execute
      Tooling::FindFilesUsingFeatureFlags.new(changed_files_pathname: rspec_changed_files_path).execute
      Tooling::FindTests.new(rspec_changed_files_path, rspec_matching_tests_path).execute
      Tooling::Mappings::PartialToViewsMappings.new(
        rspec_changed_files_path, rspec_views_including_partials_path).execute
      Tooling::FindTests.new(rspec_views_including_partials_path, rspec_matching_tests_path).execute
      Tooling::Mappings::JsToSystemSpecsMappings.new(rspec_changed_files_path, rspec_matching_tests_path).execute
      Tooling::Mappings::GraphqlBaseTypeMappings.new(rspec_changed_files_path, rspec_matching_tests_path).execute
      Tooling::Mappings::ViewToSystemSpecsMappings.new(rspec_changed_files_path, rspec_matching_tests_path).execute
      Tooling::FindChanges.new(
        from: :changed_files,
        changed_files_pathname: rspec_changed_files_path,
        predictive_tests_pathname: rspec_matching_tests_path,
        frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_path
      ).execute
      Tooling::Mappings::ViewToJsMappings.new(rspec_changed_files_path, rspec_matching_js_files_path).execute
    end

    private

    attr_reader :rspec_changed_files_path, :rspec_matching_tests_path, :rspec_views_including_partials_path,
      :frontend_fixtures_mapping_path, :rspec_matching_js_files_path
  end
end
