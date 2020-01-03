# frozen_string_literal: true

require './spec/simplecov_env'
SimpleCovEnv.start!

ENV["RAILS_ENV"] = 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'
ENV["RSPEC_ALLOW_INVALID_URLS"] = 'true'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/retry'
require 'rspec-parameterized'
require 'test_prof/recipes/rspec/let_it_be'

rspec_profiling_is_configured =
  ENV['RSPEC_PROFILING_POSTGRES_URL'].present? ||
  ENV['RSPEC_PROFILING']
branch_can_be_profiled =
  (ENV['CI_COMMIT_REF_NAME'] == 'master' ||
    ENV['CI_COMMIT_REF_NAME'] =~ /rspec-profile/)

if rspec_profiling_is_configured && (!ENV.key?('CI') || branch_can_be_profiled)
  require 'rspec_profiling/rspec'
end

if ENV['CI'] && ENV['KNAPSACK_GENERATE_REPORT'] && !ENV['NO_KNAPSACK']
  require 'knapsack'
  Knapsack::Adapters::RSpecAdapter.bind
end

# require rainbow gem String monkeypatch, so we can test SystemChecks
require 'rainbow/ext/string'
Rainbow.enabled = false

require_relative('../ee/spec/spec_helper') if Gitlab.ee?

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Requires helpers, and shared contexts/examples first since they're used in other support files

# Load these first since they may be required by other helpers
require Rails.root.join("spec/support/helpers/git_helpers.rb")

# Then the rest
Dir[Rails.root.join("spec/support/helpers/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/shared_contexts/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/shared_examples/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

quality_level = Quality::TestLevel.new

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = Rails.root

  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.infer_spec_type_from_file_location!
  config.full_backtrace = !!ENV['CI']

  unless ENV['CI']
    # Re-run failures locally with `--only-failures`
    config.example_status_persistence_file_path = './spec/examples.txt'
  end

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_spec\.rb\z}) do |metadata|
    location = metadata[:location]

    metadata[:level] = quality_level.level_for(location)
    metadata[:api] = true if location =~ %r{/spec/requests/api/}

    # do not overwrite type if it's already set
    next if metadata.key?(:type)

    match = location.match(%r{/spec/([^/]+)/})
    metadata[:type] = match[1].singularize.to_sym if match
  end

  config.include LicenseHelpers
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include CycleAnalyticsHelpers
  config.include ExpectOffense
  config.include FactoryBot::Syntax::Methods
  config.include FixtureHelpers
  config.include GitlabRoutingHelper
  config.include StubFeatureFlags
  config.include StubExperiments
  config.include StubGitlabCalls
  config.include StubGitlabData
  config.include NextInstanceOf
  config.include TestEnv
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include LoginHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include WaitHelpers, type: :feature
  config.include EmailHelpers, :mailer, type: :mailer
  config.include Warden::Test::Helpers, type: :request
  config.include Gitlab::Routing, type: :routing
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include ApiHelpers, :api
  config.include CookieHelper, :js
  config.include InputHelper, :js
  config.include SelectionHelper, :js
  config.include InspectRequests, :js
  config.include WaitForRequests, :js
  config.include LiveDebugger, :js
  config.include MigrationsHelpers, :migration
  config.include RedisHelpers
  config.include Rails.application.routes.url_helpers, type: :routing
  config.include PolicyHelpers, type: :policy
  config.include MemoryUsageHelper
  config.include ExpectRequestWithStatus, type: :request
  config.include RailsHelpers

  if ENV['CI']
    # This includes the first try, i.e. tests will be run 4 times before failing.
    config.default_retry_count = 4
    config.reporter.register_listener(
      RspecFlaky::Listener.new,
      :example_passed,
      :dump_summary)
  end

  config.before(:suite) do
    Timecop.safe_mode = true
    TestEnv.init
  end

  config.after(:all) do
    TestEnv.clean_test_path
  end

  config.before do |example|
    # Enable all features by default for testing
    allow(Feature).to receive(:enabled?) { true }

    enabled = example.metadata[:enable_rugged].present?

    # Disable Rugged features by default
    Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.each do |flag|
      allow(Feature).to receive(:enabled?).with(flag).and_return(enabled)
    end

    allow(Gitlab::GitalyClient).to receive(:can_use_disk?).and_return(enabled)

    # The following can be removed when we remove the staged rollout strategy
    # and we can just enable it using instance wide settings
    # (ie. ApplicationSetting#auto_devops_enabled)
    allow(Feature).to receive(:enabled?)
      .with(:force_autodevops_on_by_default, anything)
      .and_return(false)

    # Enable Marginalia feature for all specs in the test suite.
    allow(Gitlab::Marginalia).to receive(:cached_feature_enabled?).and_return(true)

    # The following can be removed once Vue Issuable Sidebar
    # is feature-complete and can be made default in place
    # of older sidebar.
    # See https://gitlab.com/groups/gitlab-org/-/epics/1863
    allow(Feature).to receive(:enabled?)
      .with(:vue_issuable_sidebar, anything)
      .and_return(false)
    allow(Feature).to receive(:enabled?)
      .with(:vue_issuable_epic_sidebar, anything)
      .and_return(false)

    # Stub these calls due to being expensive operations
    # It can be reenabled for specific tests via:
    #
    # allow(DetectRepositoryLanguagesWorker).to receive(:perform_async).and_call_original
    # allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
    allow(DetectRepositoryLanguagesWorker).to receive(:perform_async).and_return(true)
    allow(Gitlab::Git::KeepAround).to receive(:execute)

    Gitlab::ThreadMemoryCache.cache_backend.clear

    # Temporary patch to force admin mode to be active by default in tests when
    # using the feature flag :user_mode_in_session, since this will require
    # modifying a significant number of specs to test both states for admin
    # mode enabled / disabled.
    #
    # See https://gitlab.com/gitlab-org/gitlab/issues/31511
    # See gitlab/spec/support/helpers/admin_mode_helpers.rb
    #
    # If it is required to have the real behaviour that an admin is signed in
    # with normal user mode and needs to switch to admin mode, it is possible to
    # mark such tests with the `do_not_mock_admin_mode` metadata tag, e.g:
    #
    # context 'some test with normal user mode', :do_not_mock_admin_mode do ... end
    unless example.metadata[:do_not_mock_admin_mode]
      allow_any_instance_of(Gitlab::Auth::CurrentUserMode).to receive(:admin_mode?) do |current_user_mode|
        current_user_mode.send(:user)&.admin?
      end
    end
  end

  config.around(:example, :quarantine) do |example|
    # Skip tests in quarantine unless we explicitly focus on them.
    example.run if config.inclusion_filter[:quarantine]
  end

  config.before(:example, :request_store) do
    RequestStore.begin!
  end

  config.after(:example, :request_store) do
    RequestStore.end!
    RequestStore.clear!
  end

  config.after do
    Fog.unmock! if Fog.mock?
  end

  config.after do
    Gitlab::CurrentSettings.clear_in_memory_application_settings!
  end

  config.before(:example, :mailer) do
    reset_delivered_emails!
  end

  config.before(:example, :prometheus) do
    matching_files = File.join(::Prometheus::Client.configuration.multiprocess_files_dir, "*.db")
    Dir[matching_files].map { |filename| File.delete(filename) if File.file?(filename) }

    Gitlab::Metrics.reset_registry!
  end

  config.around(:each, :use_clean_rails_memory_store_caching) do |example|
    caching_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    example.run

    Rails.cache = caching_store
  end

  config.around do |example|
    # Wrap each example in it's own context to make sure the contexts don't
    # leak
    Labkit::Context.with_context { example.run }
  end

  config.around(:each, :clean_gitlab_redis_cache) do |example|
    redis_cache_cleanup!

    example.run

    redis_cache_cleanup!
  end

  config.around(:each, :clean_gitlab_redis_shared_state) do |example|
    redis_shared_state_cleanup!

    example.run

    redis_shared_state_cleanup!
  end

  config.around(:each, :clean_gitlab_redis_queues) do |example|
    redis_queues_cleanup!

    example.run

    redis_queues_cleanup!
  end

  config.around(:each, :use_clean_rails_memory_store_fragment_caching) do |example|
    caching_store = ActionController::Base.cache_store
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.perform_caching = true

    example.run

    ActionController::Base.perform_caching = false
    ActionController::Base.cache_store = caching_store
  end

  config.around(:each, :use_sql_query_cache) do |example|
    ActiveRecord::Base.cache do
      example.run
    end
  end

  # The :each scope runs "inside" the example, so this hook ensures the DB is in the
  # correct state before any examples' before hooks are called. This prevents a
  # problem where `ScheduleIssuesClosedAtTypeChange` (or any migration that depends
  # on background migrations being run inline during test setup) can be broken by
  # altering Sidekiq behavior in an unrelated spec like so:
  #
  # around do |example|
  #   Sidekiq::Testing.fake! do
  #     example.run
  #   end
  # end
  config.before(:context, :migration) do
    schema_migrate_down!
  end

  # Each example may call `migrate!`, so we must ensure we are migrated down every time
  config.before(:each, :migration) do
    use_fake_application_settings

    schema_migrate_down!
  end

  config.after(:context, :migration) do
    schema_migrate_up!

    Gitlab::CurrentSettings.clear_in_memory_application_settings!
  end

  # This makes sure the `ApplicationController#can?` method is stubbed with the
  # original implementation for all view specs.
  config.before(:each, type: :view) do
    allow(view).to receive(:can?) do |*args|
      Ability.allowed?(*args)
    end
  end

  config.before(:each, :http_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_http).and_return(['1.1.1.1:80'])
  end

  config.before(:each, :https_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_https).and_return(['1.1.1.1:443'])
  end

  config.before(:each, :http_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_http).and_return(false)
  end

  config.before(:each, :https_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_https).and_return(false)
  end

  # We can't use an `around` hook here because the wrapping transaction
  # is not yet opened at the time that is triggered
  config.prepend_before do
    Gitlab::Database.set_open_transactions_baseline
  end

  config.append_after do
    Gitlab::Database.reset_open_transactions_baseline
  end
end

# add simpler way to match asset paths containing digest strings
RSpec::Matchers.define :match_asset_path do |expected|
  match do |actual|
    path = Regexp.escape(expected)
    extname = Regexp.escape(File.extname(expected))
    digest_regex = Regexp.new(path.sub(extname, "(?:-\\h+)?#{extname}") << '$')
    digest_regex =~ actual
  end

  failure_message do |actual|
    "expected that #{actual} would include an asset path for #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not include an asset path for  #{expected}"
  end
end

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

# Use FactoryBot 4.x behavior:
# https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#associations
FactoryBot.use_parent_strategy = false

ActiveRecord::Migration.maintain_test_schema!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Prevent Rugged from picking up local developer gitconfig.
Rugged::Settings['search_path_global'] = Rails.root.join('tmp/tests').to_s

# Disable timestamp checks for invisible_captcha
InvisibleCaptcha.timestamp_enabled = false
