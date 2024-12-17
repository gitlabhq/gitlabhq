# frozen_string_literal: true

require 'test_prof/before_all/adapters/active_record'

module DbCleaner
  def all_connection_classes
    ::TestProf::BeforeAll::Adapters::ActiveRecord.all_connections.map(&:connection_class).uniq
  end

  def delete_from_all_tables!(except: [])
    except << 'ar_internal_metadata'

    DatabaseCleaner.clean_with(:deletion, cache_tables: false, except: except)
  end

  def deletion_except_tables
    %w[
      work_item_types work_item_hierarchy_restrictions
      work_item_widget_definitions work_item_related_link_restrictions
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

    # Seed required data as recreating DBs will delete it
    TestEnv.seed_db

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

    ActiveRecord::Base.clear_all_connections! # rubocop:disable Database/MultipleDatabases
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
