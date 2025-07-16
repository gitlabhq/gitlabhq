# frozen_string_literal: true

require 'test_file_finder'
require_relative 'helpers/predictive_tests_helper'

module Tooling
  class FindTests
    include Helpers::PredictiveTestsHelper

    def initialize(
      changed_files,
      mappings_file: nil,
      mappings_limit_percentage: nil
    )
      @changed_files = changed_files
      @mappings_file = mappings_file
      @mappings_limit_percentage = mappings_limit_percentage
    end

    def execute
      tff = TestFileFinder::FileFinder.new(paths: changed_files).tap do |file_finder|
        if mappings_file && !mappings_file.empty?
          file_finder.use TestFileFinder::MappingStrategies::DirectMatching.load_json(
            mappings_file,
            limit_percentage: mappings_limit_percentage,
            limit_min: 14
          )
        end

        file_finder.use TestFileFinder::MappingStrategies::PatternMatching.load('tests.yml')
      end

      tff.test_files.uniq
    end

    private

    attr_reader :changed_files, :mappings_file, :mappings_limit_percentage
  end
end
