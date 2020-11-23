# frozen_string_literal: true

#  $" is $LOADED_FEATURES, but RuboCop didn't like it
if $".include?(File.expand_path('fast_spec_helper.rb', __dir__))
  warn 'Detected fast_spec_helper is loaded first than spec_helper.'
  warn 'If running test files using both spec_helper and fast_spec_helper,'
  warn 'make sure test file with spec_helper is loaded first.'
  abort 'Aborting...'
end

require './spec/deprecation_toolkit_env'

require './spec/simplecov_env'
SimpleCovEnv.start!

require './spec/crystalball_env'
CrystalballEnv.start!

ENV["RAILS_ENV"] = 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'
ENV["RSPEC_ALLOW_INVALID_URLS"] = 'true'

require File.expand_path('../config/environment', __dir__)

require 'rspec/mocks'
require 'rspec/rails'
require 'rspec/retry'
require 'rspec-parameterized'
require 'shoulda/matchers'
require 'test_prof/recipes/rspec/let_it_be'
require 'test_prof/factory_default'

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
require Rails.root.join("spec/support/helpers/stub_requests.rb")

# Then the rest
Dir[Rails.root.join("spec/support/helpers/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/support/shared_contexts/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/support/shared_examples/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

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

  # Add :full_backtrace tag to an example if full_backtrace output is desired
  config.before(:each, full_backtrace: true) do |example|
    config.full_backtrace = true
  end

  unless ENV['CI']
    # Re-run failures locally with `--only-failures`
    config.example_status_persistence_file_path = './spec/examples.txt'
  end

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_spec\.rb\z}) do |metadata|
    location = metadata[:location]

    metadata[:level] = quality_level.level_for(location)
    metadata[:api] = true if location =~ %r{/spec/requests/api/}

    # Do not overwrite migration if it's already set
    unless metadata.key?(:migration)
      metadata[:migration] = true if metadata[:level] == :migration
    end

    # Do not overwrite schema if it's already set
    unless metadata.key?(:schema)
      metadata[:schema] = :latest if quality_level.background_migration?(location)
    end

    # Do not overwrite type if it's already set
    unless metadata.key?(:type)
      match = location.match(%r{/spec/([^/]+)/})
      metadata[:type] = match[1].singularize.to_sym if match
    end

    # Admin controller specs get auto admin mode enabled since they are
    # protected by the 'EnforcesAdminAuthentication' concern
    metadata[:enable_admin_mode] = true if location =~ %r{(ee)?/spec/controllers/admin/}
  end

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_docs\.rb\z}) do |metadata|
    metadata[:type] = :feature
  end

  config.include LicenseHelpers
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include CycleAnalyticsHelpers
  config.include FactoryBot::Syntax::Methods
  config.include FixtureHelpers
  config.include NonExistingRecordsHelpers
  config.include GitlabRoutingHelper
  config.include StubExperiments
  config.include StubGitlabCalls
  config.include StubGitlabData
  config.include NextFoundInstanceOf
  config.include NextInstanceOf
  config.include TestEnv
  config.include FileReadHelpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include LoginHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include WaitHelpers, type: :feature
  config.include WaitForRequests, type: :feature
  config.include EmailHelpers, :mailer, type: :mailer
  config.include Warden::Test::Helpers, type: :request
  config.include Gitlab::Routing, type: :routing
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include ApiHelpers, :api
  config.include CookieHelper, :js
  config.include InputHelper, :js
  config.include SelectionHelper, :js
  config.include InspectRequests, :js
  config.include LiveDebugger, :js
  config.include MigrationsHelpers, :migration
  config.include RedisHelpers
  config.include Rails.application.routes.url_helpers, type: :routing
  config.include PolicyHelpers, type: :policy
  config.include MemoryUsageHelper
  config.include ExpectRequestWithStatus, type: :request
  config.include IdempotentWorkerHelper, type: :worker
  config.include RailsHelpers
  config.include SidekiqMiddleware
  config.include StubActionCableConnection, type: :channel

  include StubFeatureFlags

  if ENV['CI'] || ENV['RETRIES']
    # This includes the first try, i.e. tests will be run 4 times before failing.
    config.default_retry_count = ENV.fetch('RETRIES', 3).to_i + 1
  end

  if ENV['FLAKY_RSPEC_GENERATE_REPORT']
    config.reporter.register_listener(
      RspecFlaky::Listener.new,
      :example_passed,
      :dump_summary)
  end

  config.before(:suite) do
    Timecop.safe_mode = true
    TestEnv.init

    # Reload all feature flags definitions
    Feature.register_definitions

    # Enable all features by default for testing
    # Reset any changes in after hook.
    stub_all_feature_flags
  end

  config.after(:all) do
    TestEnv.clean_test_path
  end

  # We can't use an `around` hook here because the wrapping transaction
  # is not yet opened at the time that is triggered
  config.prepend_before do
    Gitlab::Database.set_open_transactions_baseline
  end

  config.append_after do
    Gitlab::Database.reset_open_transactions_baseline
  end

  config.before do |example|
    if example.metadata.fetch(:stub_feature_flags, true)
      # The following can be removed when we remove the staged rollout strategy
      # and we can just enable it using instance wide settings
      # (ie. ApplicationSetting#auto_devops_enabled)
      stub_feature_flags(force_autodevops_on_by_default: false)

      # The following can be removed once Vue Issuable Sidebar
      # is feature-complete and can be made default in place
      # of older sidebar.
      # See https://gitlab.com/groups/gitlab-org/-/epics/1863
      stub_feature_flags(vue_issuable_sidebar: false)
      stub_feature_flags(vue_issuable_epic_sidebar: false)

      # Merge request widget GraphQL requests are disabled in the tests
      # for now whilst we migrate as much as we can over the GraphQL
      stub_feature_flags(merge_request_widget_graphql: false)

      # Using FortiAuthenticator as OTP provider is disabled by default in
      # tests, until we introduce it in user settings
      stub_feature_flags(forti_authenticator: false)

      enable_rugged = example.metadata[:enable_rugged].present?

      # Disable Rugged features by default
      Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.each do |flag|
        stub_feature_flags(flag => enable_rugged)
      end

      # Disable the usage of file_identifier_hash by default until it is ready
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/33867
      stub_feature_flags(file_identifier_hash: false)

      stub_feature_flags(unified_diff_components: false)

      allow(Gitlab::GitalyClient).to receive(:can_use_disk?).and_return(enable_rugged)
    else
      unstub_all_feature_flags
    end

    # Enable Marginalia feature for all specs in the test suite.
    Gitlab::Marginalia.enabled = true

    # Stub these calls due to being expensive operations
    # It can be reenabled for specific tests via:
    #
    # expect(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
    allow(Gitlab::Git::KeepAround).to receive(:execute)

    # Stub these calls due to being expensive operations
    # It can be reenabled for specific tests via:
    #
    # expect(Gitlab::JobWaiter).to receive(:wait).and_call_original
    allow_any_instance_of(Gitlab::JobWaiter).to receive(:wait)

    Gitlab::ProcessMemoryCache.cache_backend.clear

    Sidekiq::Worker.clear_all

    # Temporary patch to force admin mode to be active by default in tests when
    # using the feature flag :user_mode_in_session, since this will require
    # modifying a significant number of specs to test both states for admin
    # mode enabled / disabled.
    #
    # This will only be applied to specs below dirs in `admin_mode_mock_dirs`
    #
    # See ongoing migration: https://gitlab.com/gitlab-org/gitlab/-/issues/31511
    #
    # Until the migration is finished, if it is required to have the real
    # behaviour in any of the mocked dirs specs that an admin is signed in
    # with normal user mode and needs to switch to admin mode, it is possible to
    # mark such tests with the `do_not_mock_admin_mode` metadata tag, e.g:
    #
    # context 'some test in mocked dir', :do_not_mock_admin_mode do ... end
    admin_mode_mock_dirs = %w(
      ./ee/spec/elastic_integration
      ./ee/spec/finders
      ./ee/spec/lib
      ./ee/spec/requests/admin
      ./ee/spec/serializers
      ./ee/spec/support/shared_examples/finders/geo
      ./ee/spec/support/shared_examples/graphql/geo
      ./spec/finders
      ./spec/frontend
      ./spec/helpers
      ./spec/lib
      ./spec/requests
      ./spec/serializers
      ./spec/support/shared_examples/requests
      ./spec/support/shared_examples/lib/gitlab
      ./spec/views
      ./spec/workers
    )

    if !example.metadata[:do_not_mock_admin_mode] && example.metadata[:file_path].start_with?(*admin_mode_mock_dirs)
      allow_any_instance_of(Gitlab::Auth::CurrentUserMode).to receive(:admin_mode?) do |current_user_mode|
        current_user_mode.send(:user)&.admin?
      end
    end

    # Administrators have to re-authenticate in order to access administrative
    # functionality when feature flag :user_mode_in_session is active. Any spec
    # that requires administrative access can use the tag :enable_admin_mode
    # to avoid the second auth step (provided the user is already an admin):
    #
    # context 'some test that requires admin mode', :enable_admin_mode do ... end
    #
    # See also spec/support/helpers/admin_mode_helpers.rb
    if example.metadata[:enable_admin_mode] && !example.metadata[:do_not_mock_admin_mode]
      allow_any_instance_of(Gitlab::Auth::CurrentUserMode).to receive(:admin_mode?) do |current_user_mode|
        current_user_mode.send(:user)&.admin?
      end
    end
  end

  config.around(:example, :quarantine) do |example|
    # Skip tests in quarantine unless we explicitly focus on them.
    example.run if config.inclusion_filter[:quarantine]
  end

  config.around(:example, :request_store) do |example|
    Gitlab::WithRequestStore.with_request_store { example.run }
  end

  config.around do |example|
    # Wrap each example in it's own context to make sure the contexts don't
    # leak
    Labkit::Context.with_context { example.run }
  end

  config.around do |example|
    with_sidekiq_server_middleware do |chain|
      Gitlab::SidekiqMiddleware.server_configurator(
        metrics: false, # The metrics don't go anywhere in tests
        arguments_logger: false, # We're not logging the regular messages for inline jobs
        memory_killer: false # This is not a thing we want to do inline in tests
      ).call(chain)
      chain.add DisableQueryLimit
      chain.insert_after ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware, IsolatedRequestStore

      example.run
    end
  end

  config.after do
    Fog.unmock! if Fog.mock?
    Gitlab::CurrentSettings.clear_in_memory_application_settings!

    # Reset all feature flag stubs to default for testing
    stub_all_feature_flags
  end

  config.before(:example, :mailer) do
    reset_delivered_emails!
  end

  config.before(:example, :prometheus) do
    matching_files = File.join(::Prometheus::Client.configuration.multiprocess_files_dir, "**/*.db")
    Dir[matching_files].map { |filename| File.delete(filename) if File.file?(filename) }

    Gitlab::Metrics.reset_registry!
  end

  # This makes sure the `ApplicationController#can?` method is stubbed with the
  # original implementation for all view specs.
  config.before(:each, type: :view) do
    allow(view).to receive(:can?) do |*args|
      Ability.allowed?(*args)
    end
  end

  config.disable_monkey_patching!
end

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

# Initialize FactoryDefault to use create_default helper
TestProf::FactoryDefault.init
