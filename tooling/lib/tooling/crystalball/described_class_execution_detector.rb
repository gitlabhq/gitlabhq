# frozen_string_literal: true

require 'crystalball/map_generator/object_sources_detector'

module Tooling
  module Crystalball
    # Crystalball execution detector based on Crystalball::MapGenerator::ObjectSourcesDetector,
    # extended to be able to exclude some folders from the mapping.
    class DescribedClassExecutionDetector < ::Crystalball::MapGenerator::ObjectSourcesDetector
      attr_reader :exclude_prefixes

      def initialize(root_path:, exclude_prefixes: [])
        super(root_path: root_path)
        @exclude_prefixes = exclude_prefixes
      end

      def filter(paths)
        super.reject do |file_name|
          exclude_prefixes.any? { |prefix| file_name.start_with?(prefix) }
        end
      end
    end
  end
end
