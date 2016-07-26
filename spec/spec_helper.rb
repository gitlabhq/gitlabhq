if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start :rails
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
  config.include SearchHelpers,       type: :feature
  config.include StubConfiguration
  config.include EmailHelpers
  config.include TestEnv
  config.include ActiveJob::TestHelper
  config.include StubGitlabCalls
  config.include StubGitlabData
  config.include Rails.application.routes.url_helpers, type: :routing

  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!

  config.before(:suite) do
    TestEnv.init
  end

  config.before(:all) do
    License.destroy_all
    TestLicense.init
  end
end

FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

ActiveRecord::Migration.maintain_test_schema!
