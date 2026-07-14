# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module ChangeColumnDefault
      include ::Tooling::Danger::Suggestor

      METHODS = %w[change_column_default remove_column_default].freeze
      MIGRATION_METHODS_REGEX = /^\+\s*(.*\.)?(#{METHODS.join('|')})[(\s]/
      MIGRATION_FILES_REGEX = %r{^db/(post_)?migrate}

      DOCUMENTATION = 'https://docs.gitlab.com/development/database/avoiding_downtime_in_migrations/#changing-column-defaults'
      COMMENT =
        "Changing or removing a column default is difficult because of how Rails handles values that are equal " \
        "to the default. Make sure each affected column is declared with `columns_changing_default` **and** has " \
        "an application-defined default (an `attribute` default, or an `after_initialize` assignment guarded on " \
        "`came_from_user?`): the concern forces the column into the `INSERT`, but the written value must come " \
        "from the application because a running process cannot rely on the database default during the " \
        "deployment window. For more information, see " \
        "[Avoiding downtime in migrations documentation](#{DOCUMENTATION}).".freeze

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
