# frozen_string_literal: true

module Tooling
  module Danger
    module Database
      TIMESTAMP_MATCHER = /(?<timestamp>\d{14})/
      MIGRATION_MATCHER = %r{\A(ee/)?db/(geo/)?(post_)?migrate/}

      def find_migration_files_before(file_names, cutoff)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }
        migrations.select do |migration|
          next unless match = TIMESTAMP_MATCHER.match(migration)

          timestamp = Date.parse(match[:timestamp])
          timestamp < cutoff
        end
      end
    end
  end
end
