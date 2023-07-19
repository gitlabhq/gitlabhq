# frozen_string_literal: true

require 'yaml'

module Tooling
  module Danger
    module DatabaseDictionary
      DICTIONARY_PATH_REGEXP = %r{db/docs/.*\.yml}

      # `change_type` can be:
      #   - :added
      #   - :modified
      #   - :deleted
      def database_dictionary_files(change_type:)
        files = helper.public_send("#{change_type}_files") # rubocop:disable GitlabSecurity/PublicSend

        files.filter_map { |path| Found.new(path) if DICTIONARY_PATH_REGEXP.match?(path) }
      end

      class Found
        ATTRIBUTES = %w[
          table_name classes feature_categories description introduced_by_url milestone gitlab_schema
        ].freeze

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

        def ci_schema?
          gitlab_schema == 'gitlab_ci'
        end

        def main_schema?
          gitlab_schema == 'gitlab_main'
        end

        private

        def yaml
          @yaml ||= YAML.safe_load(raw)
        end
      end
    end
  end
end
