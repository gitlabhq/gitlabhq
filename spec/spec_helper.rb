require 'simplecov'
SimpleCov.start 'rails'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/dsl'
require 'webmock/rspec'
require 'factories'
require 'monkeypatch'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.include LoginMacros

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before :each, :type => :integration do
    DeviseSessionMock.disable
  end

  config.before do
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
      Capybara::Selenium::Driver::DEFAULT_OPTIONS[:resynchronize] = true
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.start

    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.after do
    DatabaseCleaner.clean
  end
end
