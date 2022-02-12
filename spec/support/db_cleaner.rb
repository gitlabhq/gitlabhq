# frozen_string_literal: true

module DbCleaner
  def all_connection_classes
    ::BeforeAllAdapter.all_connection_classes
  end

  def delete_from_all_tables!(except: [])
    except << 'ar_internal_metadata'

    DatabaseCleaner.clean_with(:deletion, cache_tables: false, except: except)
  end

  def deletion_except_tables
    ['work_item_types']
  end

  def setup_database_cleaner
    all_connection_classes.each do |connection_class|
      DatabaseCleaner[:active_record, { connection: connection_class }]
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
    start = Gitlab::Metrics::System.monotonic_time

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

    Gitlab::Database::Partitioning.sync_partitions_ignore_db_error

    puts "Databases re-creation done in #{Gitlab::Metrics::System.monotonic_time - start}"
  end

  def force_disconnect_all_connections!
    all_connection_classes.each do |connection_class|
      # We use `connection_pool` to avoid going through
      # Load Balancer since it does retry ops
      pool = connection_class.connection_pool

      # Force disconnect https://www.cybertec-postgresql.com/en/terminating-database-connections-in-postgresql/
      pool.connection.execute(<<-SQL)
        SELECT pg_terminate_backend(pid)
          FROM pg_stat_activity
          WHERE datname = #{pool.connection.quote(pool.db_config.database)}
            AND pid != pg_backend_pid();
      SQL

      connection_class.connection_pool.disconnect!
    end
  end
end

DbCleaner.prepend_mod_with('DbCleaner')
