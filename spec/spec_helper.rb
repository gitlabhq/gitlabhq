require './spec/simplecov_env'
SimpleCovEnv.start!

ENV["RAILS_ENV"] ||= 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/retry'

if ENV['RSPEC_PROFILING_POSTGRES_URL'] || ENV['RSPEC_PROFILING']
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
  config.include WaitForAjax, type: :feature
  config.include StubConfiguration
  config.include EmailHelpers, type: :mailer
  config.include TestEnv
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
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

#
# Maintain Geo database schema in tests. Unfortunately, we cannot simply use
# ActiveRecord::Migration.maintain_test_schema! because it hardcodes the rake
# task name:
#
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/migration.rb#L585
#
FileUtils.cd Rails.root do
  Geo::BaseRegistry.clear_all_connections!
  system("bin/rake geo:db:test:prepare")
  # Establish a new connection, the old database may be gone (db:test:prepare uses purge)
  Geo::BaseRegistry.establish_connection(Rails.configuration.geo_database)
end

ActiveRecord::Migration.maintain_test_schema!
