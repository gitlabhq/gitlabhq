unless ENV['CI']
  require 'simplecov'
  SimpleCov.start 'rails'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'webmock/rspec'
require 'email_spec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.mock_with :rspec

  config.include LoginHelpers, type: :request
  config.include GitoliteStub
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before do
    stub_gitolite!

    # !!! Observers disabled by default in tests
    ActiveRecord::Base.observers.disable(:all)
    # ActiveRecord::Base.observers.enable(:all)

    # Use tmp dir for FS manipulations
    Gitlab.config.gitolite.stub(repos_path: Rails.root.join('tmp', 'test-git-base-path'))
    FileUtils.rm_rf Gitlab.config.gitolite.repos_path
    FileUtils.mkdir_p Gitlab.config.gitolite.repos_path
  end
end
