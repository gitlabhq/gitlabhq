# frozen_string_literal: true

require 'yaml'

module Tooling
  module Danger
    module FeatureFlag
      # `change_type` can be:
      #   - :added
      #   - :modified
      #   - :deleted
      def feature_flag_files(change_type:)
        files = helper.public_send("#{change_type}_files") # rubocop:disable GitlabSecurity/PublicSend

        files.select { |path| path =~ %r{\A(ee/)?config/feature_flags/} }.map { |path| Found.new(path) }
      end

      class Found
        attr_reader :path

        def initialize(path)
          @path = path
        end

        def raw
          @raw ||= File.read(path)
        end

        def group
          @group ||= yaml['group']
        end

        def default_enabled
          @default_enabled ||= yaml['default_enabled']
        end

        def rollout_issue_url
          @rollout_issue_url ||= yaml['rollout_issue_url']
        end

        def group_match_mr_label?(mr_group_label)
          mr_group_label == group
        end

        private

        def yaml
          @yaml ||= YAML.safe_load(raw)
        end
      end
    end
  end
end
