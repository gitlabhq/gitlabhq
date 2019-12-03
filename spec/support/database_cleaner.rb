# frozen_string_literal: true

require 'database_cleaner/active_record/deletion'
require_relative 'db_cleaner'

module FakeInformationSchema
  # Work around a bug in DatabaseCleaner when using the deletion strategy:
  # https://github.com/DatabaseCleaner/database_cleaner/issues/347
  #
  # On MySQL, if the information schema is said to exist, we use an inaccurate
  # row count leading to some tables not being cleaned when they should
  def information_schema_exists?(_connection)
    false
  end
end

DatabaseCleaner::ActiveRecord::Deletion.prepend(FakeInformationSchema)

RSpec.configure do |config|
  include DbCleaner

  # Ensure all sequences are reset at the start of the suite run
  config.before(:suite) do
    setup_database_cleaner
    DatabaseCleaner.clean_with(:truncation)
  end

  config.append_after(:context) do
    delete_from_all_tables!
  end

  config.append_after(:context, :migration) do
    delete_from_all_tables!

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
    tables_with_more_than_allowed_columns =
      ApplicationRecord.connection.execute("SELECT attrelid::regclass::text AS table, COUNT(*) AS column_count FROM pg_attribute GROUP BY attrelid HAVING COUNT(*) > #{max_allowed_columns}")

    if tables_with_more_than_allowed_columns.any?
      tables_with_more_than_allowed_columns.each do |result|
        puts "The #{result['table']} table has #{result['column_count']} columns."
      end
      puts "Recreating the database"
      start = Gitlab::Metrics::System.monotonic_time

      ActiveRecord::Tasks::DatabaseTasks.drop_current
      ActiveRecord::Tasks::DatabaseTasks.create_current
      ActiveRecord::Tasks::DatabaseTasks.load_schema_current
      ActiveRecord::Tasks::DatabaseTasks.migrate

      puts "Database re-creation done in #{Gitlab::Metrics::System.monotonic_time - start}"
    end
  end

  config.around(:each, :delete) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!(except: deletion_except_tables)
  end

  config.around(:each, :migration) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!
  end
end
