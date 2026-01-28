# frozen_string_literal: true

module Tooling
  module Danger
    module Database
      TIMESTAMP_MATCHER = /(?<timestamp>\d{14})/
      MIGRATION_MATCHER = %r{\A(ee/)?db/(geo/)?(post_)?migrate/}
      MODEL_PATHS = %r{\A(ee/)?app/models/}
      MODEL_CHANGES = %r{^[^#\n]*?(?:scope :|where\(|joins\()}
      MIGRATION_TYPE_WARNING_MESSAGE = <<~MSG
        Please make sure that the migration is of an [appropriate type](
        https://docs.gitlab.com/development/migration_style_guide/#choose-an-appropriate-migration-type)
        and if it's supposed to be executed before or after an existing
        migration then it must be of the same type.
      MSG

      def find_migration_files_before(file_names, cutoff)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }
        migrations.select do |migration|
          next unless match = TIMESTAMP_MATCHER.match(migration)

          timestamp = Date.parse(match[:timestamp])
          timestamp < cutoff
        end
      end

      def changes
        changed_database_paths + changed_model_paths
      end

      def changed_database_paths
        helper.changes_by_category[:database]
      end

      def changed_model_paths
        helper.all_changed_files.grep(MODEL_PATHS).select do |file|
          helper.changed_lines(file).any? { |change| change =~ MODEL_CHANGES }
        end
      end

      def check_migration_type_on_stable_branch(file_names)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }
        return if migrations.empty?

        warn MIGRATION_TYPE_WARNING_MESSAGE
      end
    end
  end
end
