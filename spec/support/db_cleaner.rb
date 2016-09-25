RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseRewinder.clean_all
  end

  config.before(:each) do |example|
    unless example.metadata[:js]
      DatabaseCleaner.start
    end
  end

  config.append_after(:each) do |example|
    if example.metadata[:js]
      DatabaseRewinder.clean
    else
      DatabaseCleaner.clean
      DatabaseRewinder.cleaners.each {|c| c.send(:reset) }
    end
  end
end
