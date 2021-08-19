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
        ActiveSupport::Notifications.unsubscribe(PreventCrossDatabaseModification.cross_database_context[:subscriber])
        PreventCrossDatabaseModification.cross_database_context[:enabled] = false
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
      return unless cross_database_context[:enabled]

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

      tables = PgQuery.parse(sql).dml_tables

      return if tables.empty?

      cross_database_context[:modified_tables_by_db][database].merge(tables)

      all_tables = cross_database_context[:modified_tables_by_db].values.map(&:to_a).flatten

      unless PreventCrossJoins.only_ci_or_only_main?(all_tables)
        raise Database::PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError,
          "Cross-database data modification queries (CI and Main) were detected within " \
          "a transaction '#{all_tables.join(", ")}' discovered"
      end
    end
  end
end

Gitlab::Database.singleton_class.prepend(
  Database::PreventCrossDatabaseModification::GitlabDatabaseMixin)

RSpec.configure do |config|
  config.include(::Database::PreventCrossDatabaseModification::SpecHelpers)

  # Using before and after blocks because the around block causes problems with the let_it_be
  # record creations. It makes an extra savepoint which breaks the transaction count logic.
  config.before(:each, :prevent_cross_database_modification) do
    with_cross_database_modification_prevented
  end

  config.after(:each, :prevent_cross_database_modification) do
    cleanup_with_cross_database_modification_prevented
  end
end
