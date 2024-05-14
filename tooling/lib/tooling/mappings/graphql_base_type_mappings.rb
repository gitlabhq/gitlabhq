# frozen_string_literal: true

require_relative '../helpers/predictive_tests_helper'
require_relative '../../../../lib/gitlab_edition'

# If a GraphQL type class changed, we try to identify the other GraphQL types that potentially include this type.
module Tooling
  module Mappings
    class GraphqlBaseTypeMappings
      include Helpers::PredictiveTestsHelper

      # Checks for the implements keyword, and graphql_base_types the class name
      GRAPHQL_IMPLEMENTS_REGEXP = /implements[( ]([\w:]+)[)]?$/

      # GraphQL types are a bit scattered in the codebase based on the edition.
      #
      # Also, a higher edition is able to include lower editions.
      #   e.g. EE can include FOSS GraphQL types, and JH can include all GraphQL types
      GRAPHQL_TYPES_FOLDERS_FOSS = ['app/graphql/types'].freeze
      GRAPHQL_TYPES_FOLDERS_EE   = GRAPHQL_TYPES_FOLDERS_FOSS + ['ee/app/graphql/types', 'ee/app/graphql/ee/types']
      GRAPHQL_TYPES_FOLDERS_JH   = GRAPHQL_TYPES_FOLDERS_EE + ['jh/app/graphql/types', 'jh/app/graphql/jh/types']
      GRAPHQL_TYPES_FOLDERS      = {
        nil => GRAPHQL_TYPES_FOLDERS_FOSS,
        'ee' => GRAPHQL_TYPES_FOLDERS_EE,
        'jh' => GRAPHQL_TYPES_FOLDERS_JH
      }.freeze

      def initialize(changed_files_pathname, predictive_tests_pathname)
        @predictive_tests_pathname = predictive_tests_pathname
        @changed_files             = read_array_from_file(changed_files_pathname)
      end

      def execute
        # We go through the available editions when searching for base types
        #
        # `nil` is the FOSS edition
        matching_graphql_tests = ([nil] + ::GitlabEdition.extensions).flat_map do |edition|
          hierarchy = types_hierarchies[edition]

          filter_files.flat_map do |graphql_file|
            children_types = hierarchy[filename_to_class_name(graphql_file)]
            next if children_types.empty?

            # We find the specs for the children GraphQL types that are implementing the current GraphQL Type
            children_types.map { |filename| filename_to_spec_filename(filename) }
          end
        end.compact.uniq

        write_array_to_file(predictive_tests_pathname, matching_graphql_tests)
      end

      def filter_files
        changed_files.select do |filename|
          filename.start_with?(*GRAPHQL_TYPES_FOLDERS.values.flatten.uniq) &&
            filename.end_with?('.rb') &&
            File.exist?(filename)
        end
      end

      # Regroup all GraphQL types (by edition) that are implementing another GraphQL type.
      #
      # The key is the type that is being implemented (e.g. NoteableInterface, TodoableInterface below)
      # The value is an array of GraphQL type files that are implementing those types.
      #
      # Example output:
      #
      # {
      #   nil => {
      #     "NoteableInterface" => [
      #       "app/graphql/types/alert_management/alert_type.rb",
      #       "app/graphql/types/design_management/design_type.rb"
      #     , "TodoableInterface" => [...]
      #   },
      #   "ee" => {
      #     "NoteableInterface" => [
      #       "app/graphql/types/alert_management/alert_type.rb",
      #       "app/graphql/types/design_management/design_type.rb",
      #       "ee/app/graphql/types/epic_type.rb"],
      #    "TodoableInterface"=> [...]
      #   }
      # }
      def types_hierarchies
        return @types_hierarchies if @types_hierarchies

        @types_hierarchies = {}
        GRAPHQL_TYPES_FOLDERS.each_key do |edition|
          @types_hierarchies[edition] = Hash.new { |h, k| h[k] = [] }

          graphql_files_for_edition_glob = File.join("{#{GRAPHQL_TYPES_FOLDERS[edition].join(',')}}", '**', '*.rb')
          Dir[graphql_files_for_edition_glob].each do |graphql_file|
            graphql_base_types = File.read(graphql_file).scan(GRAPHQL_IMPLEMENTS_REGEXP)
            next if graphql_base_types.empty?

            graphql_base_classes = graphql_base_types.flatten.map { |class_name| class_name.split('::').last }
            graphql_base_classes.each do |graphql_base_class|
              @types_hierarchies[edition][graphql_base_class] += [graphql_file]
            end
          end
        end

        @types_hierarchies
      end

      def filename_to_class_name(filename)
        camelize(File.basename(filename, '.*'))
      end

      # We don't want to use active_support for this method, so we're making it ourselves
      def camelize(str)
        str.split('_').collect(&:capitalize).join
      end

      def filename_to_spec_filename(filename)
        spec_file = filename.sub('app', 'spec').sub('.rb', '_spec.rb')

        return spec_file if File.exist?(spec_file)
      end

      private

      attr_reader :changed_files, :predictive_tests_pathname
    end
  end
end
