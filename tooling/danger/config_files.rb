# frozen_string_literal: true

require 'yaml'

module Tooling
  module Danger
    module ConfigFiles
      SUGGEST_INTRODUCED_BY_COMMENT = <<~SUGGEST_COMMENT
        ```suggestion
        introduced_by_url: %<url>
        ```
      SUGGEST_COMMENT

      CONFIG_DIRS = %w[
        config/feature_flags
        config/metrics
        config/events
      ].freeze

      def add_suggestion_for_missing_introduced_by_url
        new_config_files.each do |file_name|
          config_file_lines = project_helper.file_lines(file_name)

          config_file_lines.each_with_index do |added_line, i|
            next unless added_line =~ /^introduced_by_url:\s?$/

            markdown(format(SUGGEST_INTRODUCED_BY_COMMENT, url: helper.mr_web_url), file: file_name, line: i + 1)
          end
        end
      end

      def new_config_files
        helper.added_files.select { |f| in_config_dir?(f) && f.end_with?('yml') }
      end

      private

      def in_config_dir?(path)
        CONFIG_DIRS.any? { |d| path.start_with?(d) }
      end
    end
  end
end
