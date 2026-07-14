# frozen_string_literal: true

module Database
  module MultipleDatabasesHelpers
    EXTRA_DBS = ::Gitlab::Database.all_database_names.map(&:to_sym) - [:main]

    # Throwaway abstract connection class used to hold the side connection to the
    # non-UTC Postgres instance (`postgres-tz`). Keeping it on its own abstract
    # class ensures the side connection lives in an isolated pool and never
    # touches the global `ActiveRecord::Base` connection handler.
    #
    # The pool is established/removed via the class methods below so they can be
    # called from `before(:context)`/`after(:context)` hooks (which run outside
    # the per-example transaction, avoiding the open-transaction
    # `establish_connection` guard). See spec/support/database/partition_tz.rb.
    class PartitionTzConnection < ActiveRecord::Base
      self.abstract_class = true

      # The host is overridden to `ENV['POSTGRES_TZ_HOST']` and the database to
      # the built-in `postgres` database; everything else is inherited from the
      # primary (`ApplicationRecord`) config.
      #
      # The database MUST be overridden. The `postgres-tz` instance is started
      # without any GitLab schema (deliberately -- the guard raises before any
      # DDL/table access, so the second instance needs no schema). It therefore
      # has no `gitlabhq_test` database, so inheriting the primary's `database:`
      # produces `ActiveRecord::NoDatabaseError` / `PG::ConnectionBad: database
      # "gitlabhq_test" does not exist` the moment any query runs against the
      # pool (including from global spec hooks, before our example body ever
      # runs). The built-in `postgres` database always exists on a fresh
      # cluster, and the guard reads `reset_val` from `pg_settings` (a
      # cluster-wide GUC readable from any database), so connecting there is
      # sufficient to exercise the guard.
      #
      # NOTE on schema: the guard-raise examples need NO schema on this instance
      # -- they raise before any DDL/table access. Only the no-silent-corruption
      # proof needs a minimal schema, created by `setup_partition_schema!`
      # below. That minimal schema is just one schema namespace plus two PURE
      # pg_catalog views (zero GitLab tables), so it costs ~1s rather than a full
      # `db:schema:load`.
      def self.establish_tz_pool!
        primary_config = ApplicationRecord.connection_db_config

        tz_db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
          primary_config.env_name,
          'partition_tz',
          primary_config.configuration_hash.merge(
            host: ENV['POSTGRES_TZ_HOST'],
            database: 'postgres'
          )
        )

        establish_connection(tz_db_config)
      end

      # Create the MINIMAL schema that `PartitionExporter#export` needs to run
      # against the bare `postgres` database on `postgres-tz`, so the
      # no-silent-corruption proof can observe a real exported boundary instead
      # of vacuously passing on a missing-relation error.
      #
      # `export` walks the `postgres_partitioned_tables` / `postgres_partitions`
      # AR models, which are backed by VIEWS. Crucially, those views are PURE
      # pg_catalog derivations (pg_class/pg_namespace/pg_attribute/pg_inherits/
      # pg_partitioned_table) with ZERO GitLab-table dependencies, so they can be
      # created verbatim on any empty database. The `gitlab_partitions_dynamic`
      # schema is also created because the (b) partition is placed there and the
      # `postgres_partitions` view's WHERE clause references it.
      #
      # The view bodies are copied verbatim from `db/structure.sql`. If those
      # view definitions ever change there, update these copies. (They change
      # very rarely; drift would surface as an obvious query error.)
      #
      # Idempotent: safe to call from a `before(:context)` hook.
      def self.setup_partition_schema!
        connection.execute(<<~SQL)
          CREATE SCHEMA IF NOT EXISTS gitlab_partitions_dynamic;

          CREATE OR REPLACE VIEW postgres_partitioned_tables AS
           SELECT (((pg_namespace.nspname)::text || '.'::text) || (pg_class.relname)::text) AS identifier,
              pg_class.oid,
              pg_namespace.nspname AS schema,
              pg_class.relname AS name,
                  CASE partitioned_tables.partstrat
                      WHEN 'l'::"char" THEN 'list'::text
                      WHEN 'r'::"char" THEN 'range'::text
                      WHEN 'h'::"char" THEN 'hash'::text
                      ELSE NULL::text
                  END AS strategy,
              array_agg(pg_attribute.attname) AS key_columns
             FROM (((( SELECT pg_partitioned_table.partrelid,
                      pg_partitioned_table.partstrat,
                      unnest(pg_partitioned_table.partattrs) AS column_position
                     FROM pg_partitioned_table) partitioned_tables
               JOIN pg_class ON ((partitioned_tables.partrelid = pg_class.oid)))
               JOIN pg_namespace ON ((pg_class.relnamespace = pg_namespace.oid)))
               JOIN pg_attribute ON (((pg_attribute.attrelid = pg_class.oid) AND (pg_attribute.attnum = partitioned_tables.column_position))))
            WHERE (pg_namespace.nspname = "current_schema"())
            GROUP BY (((pg_namespace.nspname)::text || '.'::text) || (pg_class.relname)::text), pg_class.oid, pg_namespace.nspname, pg_class.relname,
                  CASE partitioned_tables.partstrat
                      WHEN 'l'::"char" THEN 'list'::text
                      WHEN 'r'::"char" THEN 'range'::text
                      WHEN 'h'::"char" THEN 'hash'::text
                      ELSE NULL::text
                  END;

          CREATE OR REPLACE VIEW postgres_partitions AS
           SELECT (((pg_namespace.nspname)::text || '.'::text) || (pg_class.relname)::text) AS identifier,
              pg_class.oid,
              pg_namespace.nspname AS schema,
              pg_class.relname AS name,
              (((parent_namespace.nspname)::text || '.'::text) || (parent_class.relname)::text) AS parent_identifier,
              pg_get_expr(pg_class.relpartbound, pg_inherits.inhrelid) AS condition
             FROM ((((pg_class
               JOIN pg_namespace ON ((pg_namespace.oid = pg_class.relnamespace)))
               JOIN pg_inherits ON ((pg_class.oid = pg_inherits.inhrelid)))
               JOIN pg_class parent_class ON ((pg_inherits.inhparent = parent_class.oid)))
               JOIN pg_namespace parent_namespace ON ((parent_class.relnamespace = parent_namespace.oid)))
            WHERE (pg_class.relispartition AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name])));
        SQL
      end

      def self.teardown_tz_pool!
        remove_connection if connected?
      end
    end

    def database_exists?(database_name)
      ::Gitlab::Database.has_database?(database_name)
    end

    def skip_if_shared_database(database_name)
      skip "Skipping because #{database_name} is shared or doesn't not exist" unless database_exists?(database_name)
    end

    def skip_if_database_exists(database_name)
      skip "Skipping because database #{database_name} exists" if database_exists?(database_name)
    end

    def execute_on_each_database(query, databases: %I[main ci])
      databases = databases.select { |database_name| database_exists?(database_name) }

      Gitlab::Database::EachDatabase.each_connection(only: databases, include_shared: false) do |connection, _|
        next unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(:gitlab_shared)

        connection.execute(query)
      end
    end

    def skip_if_multiple_databases_not_setup(*databases)
      unless (databases - EXTRA_DBS).empty?
        raise "Unsupported database in #{databases}. It must be one of #{EXTRA_DBS}."
      end

      databases = EXTRA_DBS if databases.empty?
      return if databases.any? { |db| Gitlab::Database.has_config?(db) }

      skip "Skipping because none of the extra databases #{databases} are setup"
    end

    # Skip the example unless a non-UTC Postgres instance is available.
    #
    # Unlike `skip_if_multiple_databases_not_setup`, which keys off named Rails
    # databases (ci/sec/embedding) via `Gitlab::Database.has_config?`, the
    # non-UTC instance used by the partition timezone guard specs is a raw host
    # alias (`postgres-tz`), NOT a named Rails database. It can therefore never
    # appear in `EXTRA_DBS`/`has_config?`. CI exports `POSTGRES_TZ_HOST`
    # alongside the `postgres-tz` service; local GDK does not set it. So we gate
    # on the presence of that env var, mirroring the spirit of the existing
    # skip-if-absent convention while using a detection mechanism appropriate to
    # a non-Rails host.
    def skip_unless_non_utc_database_available
      return if ENV['POSTGRES_TZ_HOST'].present?

      skip "Skipping because the non-UTC database (POSTGRES_TZ_HOST) is not configured"
    end

    # Returns the connection to the non-UTC Postgres instance (`postgres-tz`).
    #
    # Safe to call from within an example: it does NOT call
    # `establish_connection` (that happens once via
    # `PartitionTzConnection.establish_tz_pool!` in the `before(:context)` hook),
    # it only fetches the connection from the already-established pool. See
    # spec/support/database/partition_tz.rb.
    def tz_connection
      ::Database::MultipleDatabasesHelpers::PartitionTzConnection.connection
    end

    def skip_if_multiple_databases_are_setup(*databases)
      unless (databases - EXTRA_DBS).empty?
        raise "Unsupported database in #{databases}. It must be one of #{EXTRA_DBS}."
      end

      databases = EXTRA_DBS if databases.empty?
      return if databases.none? { |db| Gitlab::Database.has_config?(db) }

      skip "Skipping because some of the extra databases #{databases} are setup"
    end

    def reconfigure_db_connection(name: nil, config_hash: {}, model: ActiveRecord::Base, config_model: nil)
      db_config = (config_model || model).connection_db_config

      new_db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        db_config.env_name,
        name ? name.to_s : db_config.name,
        db_config.configuration_hash.merge(config_hash)
      )

      model.establish_connection(new_db_config)
    end

    def ensure_schema_and_empty_tables
      # Ensure all schemas for both databases are migrated back
      Gitlab::Database.database_base_models.each do |_, base_model|
        with_reestablished_active_record_base do
          reconfigure_db_connection(
            model: ActiveRecord::Base,
            config_model: base_model
          )

          # Skip refreshing of attribute methods as we are inside a reconfigured DB connection
          # and these models won't exist on all databases. We refresh later after migrating all DBs.
          schema_migrate_up!(skip_refresh_attribute_methods: true)

          # Delete after migrating so that rows created during migration don't impact other
          # specs (for example, async foreign key creation rows)
          delete_from_all_tables!(except: deletion_except_tables)
        end
      end

      # ActiveRecord::Base.clear_all_connections! disconnects and clears attribute methods
      # Force a refresh to avoid schema failures.
      reset_column_in_all_models
      refresh_attribute_methods
    end

    # The usage of this method switches temporarily used `connection_handler`
    # allowing full manipulation of ActiveRecord::Base connections without
    # having side effects like:
    # - misaligned transactions since this is managed by `TestProf::BeforeAll::Adapters::ActiveRecord`
    # - removal of primary connections
    #
    # The execution within a block ensures safe cleanup of all allocated resources.
    #
    def with_reestablished_active_record_base(reconnect: true)
      connection_classes = ActiveRecord::Base
        .connection_handler
        .connection_pool_names
        .map(&:constantize)

      connection_classes.delete(ActiveRecord::PendingMigrationConnection)

      connection_class_to_config = connection_classes.index_with(&:connection_db_config)

      original_handler = ActiveRecord::Base.connection_handler
      new_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
      ActiveRecord::Base.connection_handler = new_handler

      if reconnect
        # Schema validation requires all connections to be established so we skip this validator
        # while we re-establish each connection class.
        Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
          connection_class_to_config.each { |klass, db_config| klass.establish_connection(db_config) }
        end
      end

      yield
    ensure
      ActiveRecord::Base.connection_handler = original_handler

      # Prevent connections from leaking by unpinning the connection before clearing.
      # We also need to remove the pool from `@fixture_connection_pools` so that Rails
      # does not try to unpin the connection again at the end of the test.
      if @fixture_connection_pools
        new_handler.each_connection_pool do |pool|
          @fixture_connection_pools.delete(pool)&.unpin_connection!
        end
      end

      new_handler&.clear_all_connections!
    end

    def with_db_configs(test: test_config)
      current_configurations = ActiveRecord::Base.configurations
      ActiveRecord::Base.configurations = { test: test_config }
      yield
    ensure
      ActiveRecord::Base.configurations = current_configurations
    end
  end

  module ActiveRecordBaseEstablishConnection
    def establish_connection(*args)
      # rubocop:disable Database/MultipleDatabases
      if connected? &&
          connection&.transaction_open? &&
          ActiveRecord::Base.connection_handler == ActiveRecord::Base.default_connection_handler
        raise "Cannot re-establish '#{self}.establish_connection' within an open transaction " \
          "(#{connection&.open_transactions.to_i}). Use `with_reestablished_active_record_base` " \
          "instead or add `:reestablished_active_record_base` to rspec context."
      end
      # rubocop:enable Database/MultipleDatabases

      super
    end
  end
end

ActiveRecord::Base.singleton_class.prepend(::Database::ActiveRecordBaseEstablishConnection) # rubocop:disable Database/MultipleDatabases
