require 'database_cleaner'

RSpec.configure do |config|
  config.before do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
      Capybara::Selenium::Driver::DEFAULT_OPTIONS[:resynchronize] = true
    else
      DatabaseCleaner.strategy = :transaction
    end

    unless example.metadata[:no_db]
      DatabaseCleaner.start
    end
  end

  config.after do
    unless example.metadata[:no_db]
      DatabaseCleaner.clean
    end
  end
end
