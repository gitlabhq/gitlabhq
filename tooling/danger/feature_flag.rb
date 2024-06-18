# frozen_string_literal: true

require 'yaml'
require_relative '../../lib/feature/shared'

module Tooling
  module Danger
    module FeatureFlag
      # `change_type` can be:
      #   - :added
      #   - :modified
      #   - :deleted
      def feature_flag_files(danger_helper:, change_type:)
        files = danger_helper.public_send("#{change_type}_files") # rubocop:disable GitlabSecurity/PublicSend -- we allow calling danger_helper.added_files & danger_helper.modified_files

        files.select { |path| %r{\A(ee/)?config/feature_flags/.*\.yml\z}.match?(path) }.map { |path| Found.build(path) }
      end

      Found = Struct.new(
        :path,
        :lines,
        :name,
        :feature_issue_url,
        :introduced_by_url,
        :rollout_issue_url,
        :milestone,
        :group,
        :type,
        :default_enabled,
        keyword_init: true
      ) do
        def self.build(path)
          raw = File.read(path)
          yaml = YAML.safe_load(raw)

          new(path: path, lines: raw.lines, **yaml)
        rescue Psych::Exception, StandardError
          new(path: path)
        end

        def valid?
          !missing_field?(:name)
        end

        def missing_group?
          missing_field?(:group)
        end

        def missing_feature_issue_url?
          missing_field?(:feature_issue_url)
        end

        def missing_introduced_by_url?
          missing_field?(:introduced_by_url)
        end

        def missing_rollout_issue_url?
          missing_field?(:rollout_issue_url)
        end

        def missing_milestone?
          missing_field?(:milestone)
        end

        def default_enabled?
          !!default_enabled
        end

        def group_match_mr_label?(mr_group_label)
          mr_group_label == group
        end

        def find_line_index(text)
          lines.find_index("#{text}\n")
        end

        private

        def missing_field?(field)
          self[field].nil? || self[field].empty?
        end
      end
    end
  end
end
