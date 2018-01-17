RSpec.configure do |config|
  # Ensure all sequences are reset at the start of the suite run
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.append_after(:context) do
    DatabaseCleaner.clean_with(:deletion, cache_tables: false)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js) do
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each, :truncate) do
    DatabaseCleaner.strategy = :deletion
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
end
