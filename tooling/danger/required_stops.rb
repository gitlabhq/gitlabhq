# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module RequiredStops
      include ::Tooling::Danger::Suggestor

      MIGRATION_FILES_REGEX = %r{^db/(post_)?migrate}

      MIGRATION_FINALIZE_METHODS = %w[finalize_background_migration ensure_batched_background_migration_is_finished
        finalize_batched_background_migration].freeze
      MIGRATION_FINALIZE_REGEX = /^\+\s*(.*\.)?(#{MIGRATION_FINALIZE_METHODS.join('|')})[( ]/

      DOC_URL = "https://docs.gitlab.com/ee/development/database/required_stops.html"
      WARNING_COMMENT = <<~COMMENT.freeze
        Finalizing data migration might be time consuming and require a [required stop](#{DOC_URL}).
        Check the timings of the underlying data migration.
        If possible schedule finalization for the first minor version after the next required stop.
      COMMENT

      def add_comment_for_finalized_migrations
        migration_files.each do |filename|
          add_suggestion(
            filename: filename,
            regex: MIGRATION_FINALIZE_REGEX,
            comment_text: WARNING_COMMENT
          )
        end
      end

      private

      def migration_files
        helper.all_changed_files.grep(MIGRATION_FILES_REGEX)
      end
    end
  end
end
