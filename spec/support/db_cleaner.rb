RSpec.configure do |config|
  config.around(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
