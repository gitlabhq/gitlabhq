# frozen_string_literal: true

module DbCleaner
  def base_class_for(pool)
    if pool.respond_to?(:connection_class)
      pool.connection_class
    else
      pool.connection_descriptor.name.constantize
    end
  end

  def all_connection_classes
    # In Rails 8, connection_pool_list(:writing) is no longer available.
    # Use GitLab's database_base_models instead, which returns the model
    # classes (ActiveRecord::Base, Ci::ApplicationRecord, etc.) directly.
    Gitlab::Database.database_base_models.values
  end

  def delete_from_all_tables!(except: [])
    except << 'ar_internal_metadata'

    DatabaseCleaner.clean_with(:deletion, cache_tables: false, except: except)
  end

  def deletion_except_tables
    %w[
      work_item_related_link_restrictions
    ]
  end

  def setup_database_cleaner
    all_connection_classes.each do |connection_class|
      DatabaseCleaner[:active_record, db: connection_class]
    end
  end

  def any_connection_class_with_more_than_allowed_columns?
    all_connection_classes.any? do |connection_class|
      more_than_allowed_columns?(connection_class)
    end
  end

  def more_than_allowed_columns?(connection_class)
    # Postgres maximum number of columns in a table is 1600 (https://github.com/postgres/postgres/blob/de41869b64d57160f58852eab20a27f248188135/src/include/access/htup_details.h#L23-L47).
    # And since:
    # "The DROP COLUMN form does not physically remove the column, but simply makes
    # it invisible to SQL operations. Subsequent insert and update operations in the
    # table will store a null value for the column. Thus, dropping a column is quick
    # but it will not immediately reduce the on-disk size of your table, as the space
    # occupied by the dropped column is not reclaimed.
    # The space will be reclaimed over time as existing rows are updated."
    # according to https://www.postgresql.org/docs/current/sql-altertable.html.
    # We drop and recreate the database if any table has more than 1200 columns, just to be safe.
    max_allowed_columns = 1200
    tables_with_more_than_allowed_columns = connection_class.connection.execute(<<-SQL)
      SELECT attrelid::regclass::text AS table, COUNT(*) AS column_count
        FROM pg_attribute
        GROUP BY attrelid
        HAVING COUNT(*) > #{max_allowed_columns}
    SQL

    tables_with_more_than_allowed_columns.each do |result|
      puts "The #{result['table']} (#{connection_class.connection_db_config.name}) table has #{result['column_count']} columns."
    end

    tables_with_more_than_allowed_columns.any?
  end

  def recreate_all_databases!
    start = ::Gitlab::Metrics::System.monotonic_time

    puts "Recreating the database"

    force_disconnect_all_connections!

    ActiveRecord::Tasks::DatabaseTasks.drop_current
    ActiveRecord::Tasks::DatabaseTasks.create_current
    ActiveRecord::Tasks::DatabaseTasks.load_schema_current

    # Migrate each database individually
    with_reestablished_active_record_base do
      all_connection_classes.each do |connection_class|
        ActiveRecord::Base.establish_connection(connection_class.connection_db_config) # rubocop: disable Database/EstablishConnection

        ActiveRecord::Tasks::DatabaseTasks.migrate
      end
    end

    disable_ddl_was = Feature.enabled?(:disallow_database_ddl_feature_flags, type: :ops)
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
    Gitlab::Database::Partitioning.sync_partitions_ignore_db_error
    stub_feature_flags(disallow_database_ddl_feature_flags: disable_ddl_was)

    puts "Databases re-creation done in #{::Gitlab::Metrics::System.monotonic_time - start}"
  end

  def recreate_databases_and_seed_if_needed
    # Postgres maximum number of columns in a table is 1600 (https://github.com/postgres/postgres/blob/de41869b64d57160f58852eab20a27f248188135/src/include/access/htup_details.h#L23-L47).
    # We drop and recreate the database if any table has more than 1200 columns, just to be safe.
    return false unless any_connection_class_with_more_than_allowed_columns?

    recreate_all_databases!

    true
  end

  def force_disconnect_all_connections!
    cmd = <<~SQL
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE datname = current_database()
        AND pid <> pg_backend_pid();
    SQL

    Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection|
      connection.execute(cmd)
    end

    ActiveRecord::Base.connection_handler.clear_all_connections!
  end
end

DbCleaner.prepend_mod_with('DbCleaner')

# We patch the establish_master_connection so that it establishes a connection
# using a ActiveRecord::DatabaseConfigurations::HashConfig instead of a hash.
#
# Using a HashConfig avoids resetting the name of the connection.
module PostgreSQLDatabaseTasksPatch
  def establish_master_connection
    establish_connection(
      ActiveRecord::DatabaseConfigurations::HashConfig.new(
        db_config.env_name,
        db_config.name,
        db_config.configuration_hash.merge(
          database: "postgres",
          schema_search_path: "public"
        )
      )
    )
  end
end

ActiveRecord::Tasks::PostgreSQLDatabaseTasks.prepend(PostgreSQLDatabaseTasksPatch)

# Batches per-table DELETEs into a single execute() to cut round-trips during
# suite/migration cleanup. GitLab only calls the :deletion strategy without
# :reset_ids, so we deliberately omit the base gem's sequence-reset path.
#
# The batched statement spans tables from multiple gitlab_schemas, which trips
# both GitlabSchemasValidateConnection and the PreventCrossJoins spec guard.
# We suppress both for the cleanup query only.
# Upstream: https://github.com/DatabaseCleaner/database_cleaner-active_record/pull/113
module DatabaseCleanerDeletionBatchPatch
  private

  def delete_tables(connection, table_names)
    return if table_names.empty?

    statements = table_names.map do |table_name|
      "DELETE FROM #{connection.quote_table_name(table_name)};"
    end

    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
      Gitlab::Database.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/589022') do
        connection.execute(statements.join)
      end
    end
  end
end

DatabaseCleaner::ActiveRecord::Deletion.prepend(DatabaseCleanerDeletionBatchPatch)

# disable_referential_integrity (called by the cleaner) ends with ENABLE TRIGGER
# ALL, which resets tgenabled to 'O' and silently drops ALWAYS. A pg_dump against
# a cleaned database then omits the ENABLE ALWAYS TRIGGER line, so a regenerated
# db/structure.sql loses it. Re-assert ALWAYS after cleaning.
# https://gitlab.com/gitlab-org/gitlab/-/work_items/613826
#
# Parents only (tgparentid = 0): ALTER on a partitioned parent recurses to its
# partitions, so the cloned child triggers need no statement of their own.
module DatabaseCleanerPreserveAlwaysTriggersPatch
  ALWAYS_TRIGGERS_SQL = <<~SQL
    SELECT n.nspname, c.relname, t.tgname FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE t.tgenabled = 'A' AND NOT t.tgisinternal AND t.tgparentid = 0
  SQL

  def clean
    always_triggers = connection.select_rows(ALWAYS_TRIGGERS_SQL)

    super

    always_triggers.each do |schema, table, trigger|
      connection.execute(
        "ALTER TABLE #{connection.quote_table_name("#{schema}.#{table}")} " \
          "ENABLE ALWAYS TRIGGER #{connection.quote_column_name(trigger)}"
      )
    end
  end
end

# GitLab only uses the :deletion strategy, and Deletion defines its own #clean
# (it does not inherit Truncation's), so the patch must go on Deletion.
DatabaseCleaner::ActiveRecord::Deletion.prepend(DatabaseCleanerPreserveAlwaysTriggersPatch)
