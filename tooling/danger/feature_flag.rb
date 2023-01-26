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
        ATTRIBUTES = %w[name introduced_by_url rollout_issue_url milestone type group default_enabled].freeze

        attr_reader :path

        def initialize(path)
          @path = path
        end

        ATTRIBUTES.each do |attribute|
          define_method(attribute) do
            yaml[attribute]
          end
        end

        def raw
          @raw ||= File.read(path)
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
