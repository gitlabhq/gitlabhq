# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

require 'simplecov' unless ENV['CI']

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'webmock/rspec'
require 'email_spec'
require 'sidekiq/testing/inline'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 10

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
  config.mock_with :rspec

  config.include LoginHelpers, type: :feature
  config.include LoginHelpers, type: :request
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller

  config.include TestEnv

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.

  config.before(:suite) do
    TestEnv.init(init_repos: true, repos: false)
  end
  config.before(:each) do
    TestEnv.setup_stubs
  end
end
