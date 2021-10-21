# frozen_string_literal: true

module Database
  module PreventCrossDatabaseModification
    CrossDatabaseModificationAcrossUnsupportedTablesError = Class.new(StandardError)

    module GitlabDatabaseMixin
      def allow_cross_database_modification_within_transaction(url:)
        cross_database_context = Database::PreventCrossDatabaseModification.cross_database_context
        return yield unless cross_database_context && cross_database_context[:enabled]

        transaction_tracker_enabled_was = cross_database_context[:enabled]
        cross_database_context[:enabled] = false

        yield
      ensure
        cross_database_context[:enabled] = transaction_tracker_enabled_was if cross_database_context
      end
    end

    module SpecHelpers
      def with_cross_database_modification_prevented
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          PreventCrossDatabaseModification.prevent_cross_database_modification!(payload[:connection], payload[:sql])
        end

        PreventCrossDatabaseModification.reset_cross_database_context!
        PreventCrossDatabaseModification.cross_database_context.merge!(enabled: true, subscriber: subscriber)

        yield if block_given?
      ensure
        cleanup_with_cross_database_modification_prevented if block_given?
      end

      def cleanup_with_cross_database_modification_prevented
        if PreventCrossDatabaseModification.cross_database_context
          ActiveSupport::Notifications.unsubscribe(PreventCrossDatabaseModification.cross_database_context[:subscriber])
          PreventCrossDatabaseModification.cross_database_context[:enabled] = false
        end
      end
    end

    def self.cross_database_context
      Thread.current[:transaction_tracker]
    end

    def self.reset_cross_database_context!
      Thread.current[:transaction_tracker] = initial_data
    end

    def self.initial_data
      {
        enabled: false,
        transaction_depth_by_db: Hash.new { |h, k| h[k] = 0 },
        modified_tables_by_db: Hash.new { |h, k| h[k] = Set.new }
      }
    end

    def self.prevent_cross_database_modification!(connection, sql)
      return unless cross_database_context
      return unless cross_database_context[:enabled]

      return if connection.pool.instance_of?(ActiveRecord::ConnectionAdapters::NullPool)

      database = connection.pool.db_config.name

      if sql.start_with?('SAVEPOINT')
        cross_database_context[:transaction_depth_by_db][database] += 1

        return
      elsif sql.start_with?('RELEASE SAVEPOINT', 'ROLLBACK TO SAVEPOINT')
        cross_database_context[:transaction_depth_by_db][database] -= 1
        if cross_database_context[:transaction_depth_by_db][database] <= 0
          cross_database_context[:modified_tables_by_db][database].clear
        end

        return
      end

      return if cross_database_context[:transaction_depth_by_db].values.all?(&:zero?)

      # PgQuery might fail in some cases due to limited nesting:
      # https://github.com/pganalyze/pg_query/issues/209
      parsed_query = PgQuery.parse(sql)
      tables = sql.downcase.include?(' for update') ? parsed_query.tables : parsed_query.dml_tables

      # We have some code where plans and gitlab_subscriptions are lazily
      # created and this causes lots of spec failures
      # https://gitlab.com/gitlab-org/gitlab/-/issues/343394
      tables -= %w[plans gitlab_subscriptions]

      return if tables.empty?

      # All migrations will write to schema_migrations in the same transaction.
      # It's safe to ignore this since schema_migrations exists in all
      # databases
      return if tables == ['schema_migrations']

      cross_database_context[:modified_tables_by_db][database].merge(tables)

      all_tables = cross_database_context[:modified_tables_by_db].values.map(&:to_a).flatten
      schemas = Database::GitlabSchema.table_schemas(all_tables)

      if schemas.many?
        raise Database::PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError,
          "Cross-database data modification of '#{schemas.to_a.join(", ")}' were detected within " \
          "a transaction modifying the '#{all_tables.to_a.join(", ")}' tables." \
          "Please refer to https://docs.gitlab.com/ee/development/database/multiple_databases.html#removing-cross-database-transactions for details on how to resolve this exception."
      end
    end
  end
end

Gitlab::Database.singleton_class.prepend(
  Database::PreventCrossDatabaseModification::GitlabDatabaseMixin)

CROSS_DB_MODIFICATION_ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-database-modification-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(::Database::PreventCrossDatabaseModification::SpecHelpers)

  # Using before and after blocks because the around block causes problems with the let_it_be
  # record creations. It makes an extra savepoint which breaks the transaction count logic.
  config.before do |example_file|
    if CROSS_DB_MODIFICATION_ALLOW_LIST.exclude?(example_file.file_path)
      with_cross_database_modification_prevented
    end
  end

  config.after do |example_file|
    cleanup_with_cross_database_modification_prevented
  end
end
