# frozen_string_literal: true

require_relative '../helpers/predictive_tests_helper'
require_relative '../../../../lib/gitlab_edition'

# Returns system specs files that are related to the Rails views files that were changed in the MR.
module Tooling
  module Mappings
    class ViewToSystemSpecsMappings
      include Helpers::PredictiveTestsHelper

      def initialize(changed_files_pathname, predictive_tests_pathname, view_base_folder: 'app/views')
        @predictive_tests_pathname = predictive_tests_pathname
        @changed_files             = read_array_from_file(changed_files_pathname)
        @view_base_folders         = folders_for_available_editions(view_base_folder)
      end

      def execute
        found_system_specs = []

        filter_files.each do |modified_view_file|
          system_specs_exact_match = find_system_specs_exact_match(modified_view_file)
          if system_specs_exact_match
            found_system_specs << system_specs_exact_match
            next
          else
            system_specs_parent_folder_match = find_system_specs_parent_folder_match(modified_view_file)
            found_system_specs += system_specs_parent_folder_match unless system_specs_parent_folder_match.empty?
          end
        end

        write_array_to_file(predictive_tests_pathname, found_system_specs.compact.uniq.sort)
      end

      private

      attr_reader :changed_files, :predictive_tests_pathname, :view_base_folders

      # Keep the views files that are in the @view_base_folders folder
      def filter_files
        @_filter_files ||= changed_files.select do |filename|
          filename.start_with?(*view_base_folders) &&
            File.basename(filename).end_with?('.html.haml') &&
            File.exist?(filename)
        end
      end

      def find_system_specs_exact_match(view_file)
        potential_spec_file = to_feature_spec_folder(view_file).sub('.html.haml', '_spec.rb')

        potential_spec_file if File.exist?(potential_spec_file)
      end

      def find_system_specs_parent_folder_match(view_file)
        parent_system_specs_folder = File.dirname(to_feature_spec_folder(view_file))

        Dir["#{parent_system_specs_folder}/**/*_spec.rb"]
      end

      # e.g. go from app/views/groups/merge_requests.html.haml to spec/features/groups/merge_requests.html.haml
      def to_feature_spec_folder(view_file)
        view_file.sub(%r{(ee/|jh/)?app/views}, '\1spec/features')
      end
    end
  end
end
