# frozen_string_literal: true

require 'test_file_finder'
require_relative 'helpers/predictive_tests_helper'

module Tooling
  class FindTests
    include Helpers::PredictiveTestsHelper

    def initialize(changed_files_pathname, predictive_tests_pathname)
      @predictive_tests_pathname = predictive_tests_pathname
      @changed_files             = read_array_from_file(changed_files_pathname)
    end

    def execute
      tff = TestFileFinder::FileFinder.new(paths: changed_files).tap do |file_finder|
        file_finder.use TestFileFinder::MappingStrategies::PatternMatching.load('tests.yml')

        if ENV['RSPEC_TESTS_MAPPING_ENABLED'] == 'true'
          file_finder.use TestFileFinder::MappingStrategies::DirectMatching.load_json(ENV['RSPEC_TESTS_MAPPING_PATH'])
        end
      end

      write_array_to_file(predictive_tests_pathname, tff.test_files.uniq)
    end

    private

    attr_reader :changed_files, :matching_tests, :predictive_tests_pathname
  end
end
