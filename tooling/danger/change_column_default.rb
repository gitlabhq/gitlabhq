# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module ChangeColumnDefault
      include ::Tooling::Danger::Suggestor

      METHODS = %w[change_column_default remove_column_default].freeze
      MIGRATION_METHODS_REGEX = /^\+\s*(.*\.)?(#{METHODS.join('|')})[(\s]/
      MIGRATION_FILES_REGEX = %r{^db/(post_)?migrate}

      DOCUMENTATION = 'https://docs.gitlab.com/ee/development/database/avoiding_downtime_in_migrations.html#changing-column-defaults'
      COMMENT =
        "Changing column default is difficult because of how Rails handles values that are equal to the default. " \
        "Please make sure all columns are declared as `columns_changing_default`. " \
        "For more information, see [Avoiding downtime in migrations documentation](#{DOCUMENTATION}).".freeze

      def add_comment_for_change_column_default
        migration_files.each do |filename|
          add_suggestion(filename: filename, regex: MIGRATION_METHODS_REGEX, comment_text: COMMENT)
        end
      end

      def migration_files
        helper.all_changed_files.grep(MIGRATION_FILES_REGEX)
      end
    end
  end
end
