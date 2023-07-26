# frozen_string_literal: true

module Tooling
  module Danger
    module Database
      TIMESTAMP_MATCHER = /(?<timestamp>\d{14})/
      MIGRATION_MATCHER = %r{\A(ee/)?db/(geo/)?(post_)?migrate/}
      MODEL_PATHS = %r{\A(ee/)?app/models/}
      MODEL_CHANGES = %r{^[^#\n]*?(?:scope :|where\(|joins\()}

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
    end
  end
end
