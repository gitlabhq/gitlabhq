# frozen_string_literal: true

require_relative '../helpers/predictive_tests_helper'
require_relative '../../../../lib/gitlab_edition'

# Returns view files that include the potential rails partials from the changed files passed as input.
module Tooling
  module Mappings
    class PartialToViewsMappings
      include Helpers::PredictiveTestsHelper

      def initialize(changed_files_pathname, views_with_partials_pathname, view_base_folder: 'app/views')
        @views_with_partials_pathname = views_with_partials_pathname
        @changed_files             = read_array_from_file(changed_files_pathname)
        @view_base_folders         = folders_for_available_editions(view_base_folder)
      end

      def execute
        views_including_modified_partials = []

        views_globs = view_base_folders.map { |view_base_folder| "#{view_base_folder}/**/*.html.haml" }
        Dir[*views_globs].each do |view_file|
          included_partial_names = find_pattern_in_file(view_file, partials_keywords_regexp)
          next if included_partial_names.empty?

          included_partial_names.each do |included_partial_name|
            if view_includes_modified_partial?(view_file, included_partial_name)
              views_including_modified_partials << view_file
            end
          end
        end

        write_array_to_file(views_with_partials_pathname, views_including_modified_partials)
      end

      def filter_files
        @_filter_files ||= changed_files.select do |filename|
          filename.start_with?(*view_base_folders) &&
            File.basename(filename).start_with?('_') &&
            File.basename(filename).end_with?('.html.haml') &&
            File.exist?(filename)
        end
      end

      def partials_keywords_regexp
        partial_keywords = filter_files.map do |partial_filename|
          extract_partial_keyword(partial_filename)
        end

        partial_regexps = partial_keywords.map do |keyword|
          %r{(?:render|render_if_exists)(?: |\()(?:partial: ?)?['"]([\w\-_/]*#{keyword})['"]}
        end

        Regexp.union(partial_regexps)
      end

      # e.g. if app/views/clusters/clusters/_sidebar.html.haml was modified, the partial keyword is `sidebar`.
      def extract_partial_keyword(partial_filename)
        File.basename(partial_filename).delete_prefix('_').delete_suffix('.html.haml')
      end

      # Why do we need this method?
      #
      # Assume app/views/clusters/clusters/_sidebar.html.haml was modified in the MR.
      #
      # Suppose now you find = render 'sidebar' in a view. Is this view including the sidebar partial
      # that was modified, or another partial called "_sidebar.html.haml" somewhere else?
      def view_includes_modified_partial?(view_file, included_partial_name)
        view_file_parent_folder        = File.dirname(view_file)
        included_partial_filename      = reconstruct_partial_filename(included_partial_name)
        included_partial_relative_path = File.join(view_file_parent_folder, included_partial_filename)

        # We do this because in render (or render_if_exists)
        # apparently looks for partials in other GitLab editions
        #
        # Example:
        #
        # ee/app/views/events/_epics_filter.html.haml is used in app/views/shared/_event_filter.html.haml
        # with render_if_exists 'events/epics_filter'
        included_partial_absolute_paths = view_base_folders.map do |view_base_folder|
          File.join(view_base_folder, included_partial_filename)
        end

        filter_files.include?(included_partial_relative_path) ||
          (filter_files & included_partial_absolute_paths).any?
      end

      def reconstruct_partial_filename(partial_name)
        partial_path          = partial_name.split('/')[..-2]
        partial_filename      = partial_name.split('/').last
        full_partial_filename = "_#{partial_filename}.html.haml"

        return full_partial_filename if partial_path.empty?

        File.join(partial_path.join('/'), full_partial_filename)
      end

      def find_pattern_in_file(file, pattern)
        File.read(file).scan(pattern).flatten.compact.uniq
      end

      private

      attr_reader :changed_files, :views_with_partials_pathname, :view_base_folders
    end
  end
end
