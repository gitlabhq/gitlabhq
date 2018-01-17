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
    DatabaseCleaner.strategy = :deletion, { except: %w[licenses] }
  end

  config.before(:each, :delete) do
    DatabaseCleaner.strategy = :deletion, { except: %w[licenses] }
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
