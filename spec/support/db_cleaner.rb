require 'database_cleaner/active_record/deletion'

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
  # Ensure all sequences are reset at the start of the suite run
  config.before(:suite) do
    setup_database_cleaner
    DatabaseCleaner.clean_with(:truncation)
  end

  config.append_after(:context) do
    DatabaseCleaner.clean_with(:deletion, cache_tables: false)
  end

  config.before(:each) do
    setup_database_cleaner
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js) do
    DatabaseCleaner.strategy = :deletion, { except: %w[licenses], cache_tables: false }
  end

  config.before(:each, :delete) do
    DatabaseCleaner.strategy = :deletion, { except: %w[licenses], cache_tables: false }
  end

  config.before(:each, :migration) do
    DatabaseCleaner.strategy = :deletion, { cache_tables: false }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  def setup_database_cleaner
    if Gitlab::Geo.geo_database_configured?
      DatabaseCleaner[:active_record, { connection: Geo::BaseRegistry }]
    end

    DatabaseCleaner[:active_record, { connection: ActiveRecord::Base }]
  end
end
