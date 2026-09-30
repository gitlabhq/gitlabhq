# frozen_string_literal: true

require_relative '../../../quality/test_level'

# Maps a changed GraphQL query file to the specs that read it.
module Tooling
  module Mappings
    class GraphqlQueryDocumentMappings
      SPEC_GLOB = Quality::TestLevel.new(['', 'ee/', 'jh/']).pattern(:integration)
      HELPER_CALL = 'get_graphql_query_as_string'
      EDITION_PREFIX_REGEXP = %r{\A(?:ee/|jh/)?app/assets/javascripts/}

      def initialize(changed_files)
        @changed_files = changed_files
      end

      def execute
        filter_files.flat_map { |graphql_file| specs_reading(graphql_file) }.uniq
      end

      def filter_files
        changed_files.select { |filename| filename.end_with?('.graphql') }
      end

      private

      attr_reader :changed_files

      # A spec reads a query file when it calls the helper AND quotes that file's path
      # somewhere in its source, whether directly in the call or via a local variable.
      #
      # No spec quotes a fragment's path, so run every reader spec in this case.
      def specs_reading(graphql_file)
        return specs_using_helper if graphql_file.end_with?('.fragment.graphql')

        relative_path = graphql_file.sub(EDITION_PREFIX_REGEXP, '')

        spec_sources.select do |_, source|
          source.include?(HELPER_CALL) &&
            (source.include?("'#{relative_path}'") || source.include?("\"#{relative_path}\""))
        end.keys
      end

      def specs_using_helper
        spec_sources.select { |_, source| source.include?(HELPER_CALL) }.keys
      end

      def spec_sources
        # rubocop:disable Rails/IndexWith -- this script runs under plain ruby, no ActiveSupport
        @spec_sources ||= Dir[SPEC_GLOB].to_h { |spec_file| [spec_file, File.read(spec_file)] }
        # rubocop:enable Rails/IndexWith
      end
    end
  end
end
