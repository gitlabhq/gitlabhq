if ENV['SIMPLECOV']
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.start :rails do
    if ENV['CI_BUILD_NAME']
      coverage_dir "coverage/#{ENV['CI_BUILD_NAME']}"
      command_name ENV['CI_BUILD_NAME']
      merge_timeout 7200
    end
  end
end

ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'sidekiq/testing/inline'
require 'rspec/retry'

if ENV['CI']
  require 'knapsack'
  Knapsack::Adapters::RSpecAdapter.bind
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
  config.mock_with :rspec

  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.include Devise::TestHelpers, type: :controller
  config.include LoginHelpers,        type: :feature
  config.include LoginHelpers,        type: :request
  config.include StubConfiguration
  config.include EmailHelpers
  config.include TestEnv
  config.include ActiveJob::TestHelper
  config.include StubGitlabCalls
  config.include StubGitlabData

  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!

  config.before(:suite) do
    TestEnv.init
  end
end

FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

ActiveRecord::Migration.maintain_test_schema!
