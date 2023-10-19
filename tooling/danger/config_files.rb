# frozen_string_literal: true

require 'yaml'
require_relative 'suggestor'

module Tooling
  module Danger
    module ConfigFiles
      include ::Tooling::Danger::Suggestor

      MISSING_INTRODUCED_BY_REGEX = /^\+?(?<attr_name>\s*introduced_by_url):\s*$/

      CONFIG_DIRS = %w[
        config/feature_flags
        config/metrics
        config/events
        ee/config/feature_flags
        ee/config/saas_features
      ].freeze

      def add_suggestion_for_missing_introduced_by_url
        new_config_files.each do |filename|
          add_suggestion(
            filename: filename,
            regex: MISSING_INTRODUCED_BY_REGEX,
            replacement: "\\k<attr_name>: #{helper.mr_web_url}"
          )
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
