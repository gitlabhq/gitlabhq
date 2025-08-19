# frozen_string_literal: true

require 'test_file_finder'
require_relative 'helpers/predictive_tests_helper'

module Tooling
  class FindFilesUsingFeatureFlags
    include Helpers::PredictiveTestsHelper

    def initialize(changed_files:, feature_flags_base_folder: 'config/feature_flags')
      @changed_files              = changed_files
      @feature_flags_base_folders = folders_for_available_editions(feature_flags_base_folder)
    end

    def execute
      return [] unless filter_files.any?

      ff_union_regexp = Regexp.union(feature_flag_filenames)
      ruby_files.select { |ruby_file| ruby_file if ff_union_regexp.match?(File.read(ruby_file)) }.uniq
    end

    def filter_files
      @_filter_files ||= changed_files.select do |filename|
        filename.start_with?(*feature_flags_base_folders) &&
          File.basename(filename).end_with?('.yml') &&
          File.exist?(filename)
      end
    end

    private

    def feature_flag_filenames
      filter_files.map do |feature_flag_pathname|
        File.basename(feature_flag_pathname).delete_suffix('.yml')
      end
    end

    def ruby_files
      Dir["**/*.rb"].reject { |pathname| pathname.start_with?('vendor') }
    end

    attr_reader :changed_files, :feature_flags_base_folders
  end
end
