# frozen_string_literal: true

require 'test_file_finder'
require_relative 'helpers/file_handler'

module Tooling
  class FindTests
    include Helpers::FileHandler

    def initialize(changes_file, matching_tests_paths)
      @matching_tests_paths = matching_tests_paths
      @changed_files        = read_array_from_file(changes_file)
    end

    def execute
      tff = TestFileFinder::FileFinder.new(paths: changed_files).tap do |file_finder|
        file_finder.use TestFileFinder::MappingStrategies::PatternMatching.load('tests.yml')

        if ENV['RSPEC_TESTS_MAPPING_ENABLED'] == 'true'
          file_finder.use TestFileFinder::MappingStrategies::DirectMatching.load_json(ENV['RSPEC_TESTS_MAPPING_PATH'])
        end
      end

      write_array_to_file(matching_tests_paths, tff.test_files.uniq)
    end

    private

    attr_reader :changed_files, :matching_tests, :matching_tests_paths
  end
end
