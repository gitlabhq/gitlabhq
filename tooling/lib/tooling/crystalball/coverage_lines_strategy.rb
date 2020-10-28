# frozen_string_literal: true

require 'coverage'
require 'crystalball/map_generator/coverage_strategy'
require_relative './coverage_lines_execution_detector'

module Tooling
  module Crystalball
    # Crystalball map generator strategy based on Crystalball::MapGenerator::CoverageStrategy,
    # modified to use Coverage.start(lines: true)
    # This maintains compatibility with SimpleCov on Ruby >= 2.5 with start arguments
    # and SimpleCov.start uses Coverage.start(lines: true) by default
    class CoverageLinesStrategy < ::Crystalball::MapGenerator::CoverageStrategy
      def initialize(execution_detector = CoverageLinesExecutionDetector)
        super(execution_detector)
      end

      def after_register
        Coverage.start(lines: true)
      end
    end
  end
end
