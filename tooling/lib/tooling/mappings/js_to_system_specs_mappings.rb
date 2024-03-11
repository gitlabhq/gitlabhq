# frozen_string_literal: true

require_relative '../helpers/predictive_tests_helper'
require_relative '../../../../lib/gitlab_edition'

# Returns system specs files that are related to the JS files that were changed in the MR.
module Tooling
  module Mappings
    class JsToSystemSpecsMappings
      include Helpers::PredictiveTestsHelper

      def initialize(
        changed_files_pathname, predictive_tests_pathname,
        js_base_folder: 'app/assets/javascripts', system_specs_base_folder: 'spec/features')
        @changed_files             = read_array_from_file(changed_files_pathname)
        @predictive_tests_pathname = predictive_tests_pathname
        @js_base_folder            = js_base_folder
        @js_base_folders           = folders_for_available_editions(js_base_folder)
        @system_specs_base_folder  = system_specs_base_folder

        # Cannot be extracted to a constant, as it depends on a variable
        @first_js_folder_extract_regexp = %r{
          (?:.*/)?             # Skips the GitLab edition (e.g. ee/, jh/)
          #{@js_base_folder}/  # Most likely app/assets/javascripts/
          (?:pages/)?          # If under a pages folder, we capture the following folder
          ([\w-]*)             # Captures the first folder
        }x
      end

      def execute
        matching_system_tests = filter_files.flat_map do |edition, js_files|
          js_keywords_regexp = Regexp.union(construct_js_keywords(js_files))

          system_specs_for_edition(edition).select do |system_spec_file|
            system_spec_file if js_keywords_regexp.match?(system_spec_file)
          end
        end

        write_array_to_file(predictive_tests_pathname, matching_system_tests)
      end

      # Keep the files that are in the @js_base_folders folders
      #
      # Returns a hash, where the key is the GitLab edition, and the values the JS specs
      def filter_files
        selected_files = changed_files.select do |filename|
          filename.start_with?(*@js_base_folders) && File.exist?(filename)
        end

        selected_files.group_by { |filename| filename[/^#{Regexp.union(::GitlabEdition.extensions)}/] }
      end

      # Extract keywords in the JS filenames to be used for searching matching system specs
      def construct_js_keywords(js_files)
        js_files.map do |js_file|
          filename = js_file.scan(@first_js_folder_extract_regexp).flatten.first
          singularize(filename)
        end.uniq
      end

      # We don't want to use active_support for this method, and our singularization cases
      # are much simpler than what the active_support method would need.
      def singularize(string)
        if string.end_with?('ies')
          string.sub(/ies$/, 'y')
        # e.g. branches -> branch, protected branches -> protected branch
        elsif string.end_with?('hes')
          string.sub(/hes$/, 'h')
        elsif string.end_with?('s')
          string.sub(/s$/, '')
        else
          string
        end
      end

      def system_specs_for_edition(edition)
        all_files_in_folders_glob = File.join(@system_specs_base_folder, '**', '*')
        all_files_in_folders_glob = File.join(edition, all_files_in_folders_glob) if edition
        Dir[all_files_in_folders_glob].select { |f| File.file?(f) && f.end_with?('_spec.rb') }
      end

      private

      attr_reader :changed_files, :predictive_tests_pathname
    end
  end
end
