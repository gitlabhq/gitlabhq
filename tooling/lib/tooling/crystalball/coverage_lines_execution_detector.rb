# frozen_string_literal: true

require 'crystalball/map_generator/helpers/path_filter'

module Tooling
  module Crystalball
    # Class for detecting code execution path based on coverage information diff
    class CoverageLinesExecutionDetector
      include ::Crystalball::MapGenerator::Helpers::PathFilter

      attr_reader :exclude_prefixes

      def initialize(*args, exclude_prefixes: [])
        super(*args)
        @exclude_prefixes = exclude_prefixes
      end

      # Detects files affected during example execution based on line coverage.
      # Transforms absolute paths to relative.
      # Exclude paths outside of repository and in excluded prefixes
      #
      # @param[Hash] hash of files affected before example execution
      # @param[Hash] hash of files affected after example execution
      # @return [Array<String>]
      def detect(before, after)
        file_names = after.keys
        covered_files = file_names.reject { |file_name| same_coverage?(before, after, file_name) }
        filter(covered_files)
      end

      private

      def same_coverage?(before, after, file_name)
        before[file_name] && before[file_name][:lines] == after[file_name][:lines]
      end

      def filter(paths)
        super.reject do |file_name|
          exclude_prefixes.any? { |prefix| file_name.start_with?(prefix) }
        end
      end
    end
  end
end
