require 'database_cleaner'

RSpec.configure do |config|
  config.before do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
      Capybara::Selenium::Driver::DEFAULT_OPTIONS[:resynchronize] = true
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
