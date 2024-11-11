# frozen_string_literal: true

require_relative '../suggestor'

module Tooling
  module Danger
    module RemoteDevelopment
      module DesiredConfigGenerator
        include ::Tooling::Danger::Suggestor

        WORKSPACE_LIB = 'ee/lib/remote_development/workspace_operations'
        SHARED_CONTEXT_PATH = 'ee/spec/support/shared_contexts/remote_development'
        DESIRED_CONFIG_GENERATOR = "#{WORKSPACE_LIB}/reconcile/output/desired_config_generator.rb".freeze
        DEVFILE_PARSER = "#{WORKSPACE_LIB}/reconcile/output/devfile_parser.rb".freeze
        REMOTE_DEVELOPMENT_SHARED_CONTEXT = "#{SHARED_CONTEXT_PATH}/remote_development_shared_contexts.rb".freeze

        def add_comment_if_shared_context_updated
          return unless remote_development_shared_context_updated? && either_config_files_updated?

          # Make the suggestion on any change to the file once
          add_suggestion(
            filename: REMOTE_DEVELOPMENT_SHARED_CONTEXT,
            regex: /.+/,
            comment_text: build_comment,
            once_per_file: true
          )
        end

        private

        def build_comment
          prefix = "This merge request updated the [`shared_context`](#{REMOTE_DEVELOPMENT_SHARED_CONTEXT}) file"
          prefix.concat(" as well as the [`devfile_parser`](#{DEVFILE_PARSER}) file") if devfile_parser_updated?

          if desired_config_generator_updated?
            prefix.concat(" and the [`desired_config_generator`](#{DESIRED_CONFIG_GENERATOR}) file")
          end

          suffix = ". Please consider reviewing any changes made to the `shared_context` file is valid."
          prefix.concat(suffix)
          prefix
        end

        def either_config_files_updated?
          devfile_parser_updated? || desired_config_generator_updated?
        end

        def remote_development_shared_context_updated?
          helper.all_changed_files.include?(REMOTE_DEVELOPMENT_SHARED_CONTEXT)
        end

        def desired_config_generator_updated?
          helper.all_changed_files.include?(DESIRED_CONFIG_GENERATOR)
        end

        def devfile_parser_updated?
          helper.all_changed_files.include?(DEVFILE_PARSER)
        end
      end
    end
  end
end
