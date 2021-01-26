# frozen_string_literal: true

require 'yaml'

module Tooling
  module Danger
    module FeatureFlag
      def feature_flag_files
        @feature_flag_files ||= git.added_files.select { |path| path =~ %r{\A(ee/)?config/feature_flags/} }.map { |path| Found.new(path) }
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
