require './spec/simplecov_env'
SimpleCovEnv.start!

ENV["RAILS_ENV"] ||= 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/retry'

rspec_profiling_is_configured =
  ENV['RSPEC_PROFILING_POSTGRES_URL'] ||
  ENV['RSPEC_PROFILING']
branch_can_be_profiled =
  ENV['GITLAB_DATABASE'] == 'postgresql' &&
  (ENV['CI_COMMIT_REF_NAME'] == 'master' ||
    ENV['CI_COMMIT_REF_NAME'] =~ /rspec-profile/)

if rspec_profiling_is_configured && (!ENV.key?('CI') || branch_can_be_profiled)
  require 'rspec_profiling/rspec'
end

if ENV['CI'] && !ENV['NO_KNAPSACK']
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

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Warden::Test::Helpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include WaitForRequests, :js
  config.include WaitForAjax, :js
  config.include StubConfiguration
  config.include EmailHelpers, type: :mailer
  config.include TestEnv
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include StubGitlabCalls
  config.include StubGitlabData
  config.include ApiHelpers, :api

  config.infer_spec_type_from_file_location!

  config.define_derived_metadata(file_path: %r{/spec/requests/(ci/)?api/}) do |metadata|
    metadata[:api] = true
  end

  config.raise_errors_for_deprecations!

  config.before(:suite) do
    TestEnv.init
  end

  config.after(:suite) do
    TestEnv.cleanup
  end

  if ENV['CI']
    # Retry only on feature specs that use JS
    config.around :each, :js do |ex|
      ex.run_with_retry retry: 3
    end
  end

  config.around(:each, :caching) do |example|
    caching_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new if example.metadata[:caching]
    example.run
    Rails.cache = caching_store
  end

  config.around(:each, :redis) do |example|
    Gitlab::Redis.with(&:flushall)
    Sidekiq.redis(&:flushall)

    example.run

    Gitlab::Redis.with(&:flushall)
    Sidekiq.redis(&:flushall)
  end
end

FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

ActiveRecord::Migration.maintain_test_schema!
