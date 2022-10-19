# frozen_string_literal: true

require_relative 'db_cleaner'

RSpec.configure do |config|
  include DbCleaner

  # Ensure the database is empty at the start of the suite run with :deletion strategy
  # neither the sequence is reset nor the tables are vacuum, but this provides
  # better I/O performance on machines with slower storage
  config.before(:suite) do
    setup_database_cleaner
    DatabaseCleaner.clean_with(:deletion)
  end

  config.append_after(:context, :migration) do
    delete_from_all_tables!(except: ['work_item_types'])

    # Postgres maximum number of columns in a table is 1600 (https://github.com/postgres/postgres/blob/de41869b64d57160f58852eab20a27f248188135/src/include/access/htup_details.h#L23-L47).
    # We drop and recreate the database if any table has more than 1200 columns, just to be safe.
    if any_connection_class_with_more_than_allowed_columns?
      recreate_all_databases!

      # Seed required data as recreating DBs will delete it
      TestEnv.seed_db
    end
  end

  config.around(:each, :delete) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!(except: deletion_except_tables)

    self.class.use_transactional_tests = true
  end

  config.around(:each, :migration) do |example|
    self.class.use_transactional_tests = false

    example.run

    delete_from_all_tables!(except: ['work_item_types'])

    self.class.use_transactional_tests = true
  end
end
