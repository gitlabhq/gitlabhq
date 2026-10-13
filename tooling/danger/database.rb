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
      DELETED_MIGRATION_WARNING_MESSAGE = <<~MSG
        🗑 **Migration Deletion Detected**

        This merge request deletes the following migration file(s):

        %<migrations>s

        Migrations that have already been merged to `master` may already have run on GitLab.com and on
        self-managed instances. Deleting them causes schema inconsistency, and leaves rows in
        `schema_migrations` that point at migrations which no longer exist.

        Instead of deleting, turn the migration into a no-op: empty out `#up`/`#down` (or `#perform`), and
        add a `# no-op` comment explaining why. This change requires approval from a Database Maintainer.
        See [Delete existing migrations](https://docs.gitlab.com/development/database/deleting_migrations/)
        for details.

        If this migration was never merged to `master` (for example, it was added and then re-created with
        a new timestamp within this same merge request), this warning can be ignored.
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

      def database_reviewer_spin
        roulette.spin(nil, [:database]).first
      end

      def check_migration_type_on_stable_branch(file_names)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }
        return if migrations.empty?

        warn MIGRATION_TYPE_WARNING_MESSAGE
      end

      def check_deleted_migrations(file_names)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }
        return if migrations.empty?

        warn format(DELETED_MIGRATION_WARNING_MESSAGE, migrations: migrations.map { |m| "* `#{m}`" }.join("\n"))
      end

      def check_prevent_index_creation_disabled(file_names)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }

        migrations.each do |filename|
          Tooling::Danger::PreventIndexCreationSuggestion.new(filename, context: self).suggest
        end
      end

      def check_prevent_column_addition_disabled(file_names)
        migrations = file_names.select { |f| f.match?(MIGRATION_MATCHER) }

        migrations.each do |filename|
          Tooling::Danger::PreventColumnAdditionSuggestion.new(filename, context: self).suggest
        end
      end
    end
  end
end
