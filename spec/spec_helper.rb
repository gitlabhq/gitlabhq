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
require 'email_spec'
require 'headless'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Use capybara-webkit
Capybara.javascript_driver = :webkit

RSpec.configure do |config|
  config.mock_with :rspec

  config.include LoginMacros

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before :all do
    headless = Headless.new
    headless.start
  end

  config.before :each, type: :integration do
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

    # !!! Observers disabled by default in tests
    #
    #   Use next code to enable observers
    #   before(:each) { ActiveRecord::Base.observers.enable(:all) }
    #
    ActiveRecord::Base.observers.disable :all
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include RSpec::Rails::RequestExampleGroup, type: :request, example_group: {
    file_path: /spec\/api/
  }
end
