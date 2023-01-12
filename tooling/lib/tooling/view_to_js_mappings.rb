# frozen_string_literal: true

require_relative '../../../lib/gitlab_edition'

# Returns JS files that are related to the Rails views files that were changed in the MR.
module Tooling
  class ViewToJsMappings
    # The HTML attribute value pattern we're looking for to match an HTML file to a JS file.
    HTML_ATTRIBUTE_VALUE_REGEXP = /js-[-\w]+/.freeze

    # Search for Rails partials included in an HTML file
    RAILS_PARTIAL_INVOCATION_REGEXP = %r{(?:render|render_if_exist)(?: |\()(?:partial: ?)?['"]([\w/-]+)['"]}.freeze

    def initialize(view_base_folder: 'app/views', js_base_folder: 'app/assets/javascripts')
      @view_base_folders = folders_for_available_editions(view_base_folder)
      @js_base_folders   = folders_for_available_editions(js_base_folder)
    end

    def execute(changed_files)
      changed_view_files = view_files(changed_files)

      partials = changed_view_files.flat_map do |file|
        find_partials(file)
      end

      files_to_scan = changed_view_files + partials
      js_tags = files_to_scan.flat_map do |file|
        find_pattern_in_file(file, HTML_ATTRIBUTE_VALUE_REGEXP)
      end
      js_tags_regexp = Regexp.union(js_tags)

      @js_base_folders.flat_map do |js_base_folder|
        Dir["#{js_base_folder}/**/*.{js,vue}"].select do |js_file|
          file_content = File.read(js_file)
          js_tags_regexp.match?(file_content)
        end
      end
    end

    # Keep the files that are in the @view_base_folders folder
    def view_files(changed_files)
      changed_files.select do |filename|
        filename.start_with?(*@view_base_folders) &&
          File.exist?(filename)
      end
    end

    def folders_for_available_editions(base_folder)
      foss_prefix        = base_folder
      extension_prefixes = ::GitlabEdition.extensions.map { |prefix| "#{prefix}/#{foss_prefix}" }
      [foss_prefix, *extension_prefixes]
    end

    # Note: We only search for partials with depth 1. We don't do recursive search, as
    #       it is probably not necessary for a first iteration.
    def find_partials(file)
      partial_paths = find_pattern_in_file(file, RAILS_PARTIAL_INVOCATION_REGEXP)
      partial_paths.flat_map do |partial_path|
        view_file_folder        = File.dirname(file)
        partial_relative_folder = File.dirname(partial_path)

        dirname =
          if partial_relative_folder == '.' # The partial is in the same folder as the HTML file
            view_file_folder
          else
            File.join(view_file_folder, partial_relative_folder)
          end

        Dir["#{dirname}/_#{File.basename(partial_path)}.*"]
      end
    end

    def find_pattern_in_file(file, pattern)
      File.read(file).scan(pattern).flatten.uniq
    end
  end
end
