# frozen_string_literal: true

require 'test_file_finder'

module Tooling
  class FindTests
    def initialize(changes_file, matching_tests_paths)
      @matching_tests_paths = matching_tests_paths
      @changed_files        = File.read(changes_file).split(' ')

      File.write(matching_tests_paths, '') unless File.exist?(matching_tests_paths)

      @matching_tests = File.read(matching_tests_paths).split(' ')
    end

    def execute
      tff = TestFileFinder::FileFinder.new(paths: changed_files).tap do |file_finder|
        file_finder.use TestFileFinder::MappingStrategies::PatternMatching.load('tests.yml')

        if ENV['RSPEC_TESTS_MAPPING_ENABLED'] == 'true'
          file_finder.use TestFileFinder::MappingStrategies::DirectMatching.load_json(ENV['RSPEC_TESTS_MAPPING_PATH'])
        end
      end

      new_matching_tests = tff.test_files.uniq
      File.write(matching_tests_paths, (matching_tests + new_matching_tests).join(' '))
    end

    private

    attr_reader :changed_files, :matching_tests, :matching_tests_paths
  end
end
