require 'rubygems'
require 'spork'

Spork.prefork do
  require 'simplecov' unless ENV['CI']

  if ENV['TRAVIS']
    require 'coveralls'
    Coveralls.wear!
  end

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rails'
  require 'capybara/rspec'
  require 'webmock/rspec'
  require 'email_spec'
  require 'sidekiq/testing/inline'
  require 'capybara/poltergeist'

  # Loading more in this block will cause your tests to run faster. However,

  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  Capybara.javascript_driver = :poltergeist
  Capybara.default_wait_time = 10

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  WebMock.disable_net_connect!(allow_localhost: true)

  RSpec.configure do |config|
    config.mock_with :rspec

    config.include LoginHelpers, type: :feature
    config.include LoginHelpers, type: :request
    config.include FactoryGirl::Syntax::Methods
    config.include Devise::TestHelpers, type: :controller

    config.include TestEnv

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false

    config.before(:suite) do
      TestEnv.init(observers: false, init_repos: true, repos: false)
    end
    config.before(:each) do
      TestEnv.setup_stubs
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
