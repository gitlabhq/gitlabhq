RSpec.configure do |config|
  config.before(:suite) do
    setup_database_cleaner
    DatabaseCleaner.clean_with(:truncation)
  end

  config.append_after(:context) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    setup_database_cleaner
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: ['licenses'] }
  end

  config.before(:each, truncate: true) do
    DatabaseCleaner.strategy = :truncation, { except: ['licenses'] }
  end

  config.before(:each, :migration) do
    DatabaseCleaner.strategy = :truncation
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
