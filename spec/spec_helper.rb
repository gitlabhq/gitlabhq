# frozen_string_literal: true

#  $" is $LOADED_FEATURES, but RuboCop didn't like it
if $".include?(File.expand_path('fast_spec_helper.rb', __dir__))
  warn 'Detected fast_spec_helper is loaded first than spec_helper.'
  warn 'If running test files using both spec_helper and fast_spec_helper,'
  warn 'make sure test file with spec_helper is loaded first.'
  abort 'Aborting...'
end

# Enable deprecation warnings by default and make them more visible
# to developers to ease upgrading to newer Ruby versions.
Warning[:deprecated] = true unless ENV.key?('SILENCE_DEPRECATIONS')

require './spec/deprecation_toolkit_env'
DeprecationToolkitEnv.configure!

require './spec/knapsack_env'
KnapsackEnv.configure!

require './spec/simplecov_env'
SimpleCovEnv.start!

require './spec/crystalball_env'
CrystalballEnv.start!

ENV["RAILS_ENV"] = 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'
ENV["RSPEC_ALLOW_INVALID_URLS"] = 'true'

require_relative '../config/environment'

require 'rspec/mocks'
require 'rspec/rails'
require 'rspec/retry'
require 'rspec-parameterized'
require 'shoulda/matchers'
require 'test_prof/recipes/rspec/let_it_be'
require 'test_prof/factory_default'
require 'parslet/rig/rspec'

rspec_profiling_is_configured =
  ENV['RSPEC_PROFILING_POSTGRES_URL'].present? ||
  ENV['RSPEC_PROFILING']
branch_can_be_profiled =
  (ENV['CI_COMMIT_REF_NAME'] == 'master' ||
    ENV['CI_COMMIT_REF_NAME'] =~ /rspec-profile/)

if rspec_profiling_is_configured && (!ENV.key?('CI') || branch_can_be_profiled)
  require 'rspec_profiling/rspec'
end

# require rainbow gem String monkeypatch, so we can test SystemChecks
require 'rainbow/ext/string'
Rainbow.enabled = false

require_relative('../ee/spec/spec_helper') if Gitlab.ee?
require_relative('../jh/spec/spec_helper') if Gitlab.jh?

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

require_relative '../tooling/quality/test_level'

quality_level = Quality::TestLevel.new

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.fixture_path = Rails.root

  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.infer_spec_type_from_file_location!

  # Add :full_backtrace tag to an example if full_backtrace output is desired
  config.before(:each, full_backtrace: true) do |example|
    config.full_backtrace = true
  end

  # Attempt to troubleshoot https://gitlab.com/gitlab-org/gitlab/-/issues/297359
  if ENV['CI']
    config.after do |example|
      if example.exception.is_a?(GRPC::Unavailable)
        warn "=== gRPC unavailable detected, process list:"
        processes = `ps -ef | grep toml`
        warn processes
        warn "=== free memory"
        warn `free -m`
        warn "=== uptime"
        warn `uptime`
        warn "=== Prometheus metrics:"
        warn `curl -s -o log/gitaly-metrics.log http://localhost:9236/metrics`
        warn "=== Taking goroutine dump in log/goroutines.log..."
        warn `curl -s -o log/goroutines.log http://localhost:9236/debug/pprof/goroutine?debug=2`
      end
    end
  end

  unless ENV['CI']
    # Allow running `:focus` examples locally,
    # falling back to all tests when there is no `:focus` example.
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true

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
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include WaitHelpers, type: :feature
  config.include WaitForRequests, type: :feature
  config.include EmailHelpers, :mailer, type: :mailer
  config.include Warden::Test::Helpers, type: :request
  config.include Gitlab::Routing, type: :routing
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
  config.include StubSpamServices

  include StubFeatureFlags

  if ENV['CI'] || ENV['RETRIES']
    # This includes the first try, i.e. tests will be run 4 times before failing.
    config.default_retry_count = ENV.fetch('RETRIES', 3).to_i + 1
    config.exceptions_to_hard_fail = [DeprecationToolkitEnv::DeprecationBehaviors::SelectiveRaise::RaiseDisallowedDeprecation]
  end

  if ENV['FLAKY_RSPEC_GENERATE_REPORT']
    require_relative '../tooling/rspec_flaky/listener'

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
    Gitlab::Database.main.set_open_transactions_baseline
  end

  config.append_before do
    Thread.current[:current_example_group] = ::RSpec.current_example.metadata[:example_group]
  end

  config.append_after do
    Gitlab::Database.main.reset_open_transactions_baseline
  end

  config.before do |example|
    if example.metadata.fetch(:stub_feature_flags, true)
      # The following can be removed when we remove the staged rollout strategy
      # and we can just enable it using instance wide settings
      # (ie. ApplicationSetting#auto_devops_enabled)
      stub_feature_flags(force_autodevops_on_by_default: false)

      # Merge request widget GraphQL requests are disabled in the tests
      # for now whilst we migrate as much as we can over the GraphQL
      # stub_feature_flags(merge_request_widget_graphql: false)

      # Using FortiAuthenticator as OTP provider is disabled by default in
      # tests, until we introduce it in user settings
      stub_feature_flags(forti_authenticator: false)

      # Using FortiToken Cloud as OTP provider is disabled by default in
      # tests, until we introduce it in user settings
      stub_feature_flags(forti_token_cloud: false)

      # These feature flag are by default disabled and used in disaster recovery mode
      stub_feature_flags(ci_queueing_disaster_recovery_disable_fair_scheduling: false)
      stub_feature_flags(ci_queueing_disaster_recovery_disable_quota: false)

      enable_rugged = example.metadata[:enable_rugged].present?

      # Disable Rugged features by default
      Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.each do |flag|
        stub_feature_flags(flag => enable_rugged)
      end

      # Disable the usage of file_identifier_hash by default until it is ready
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/33867
      stub_feature_flags(file_identifier_hash: false)

      stub_feature_flags(diffs_virtual_scrolling: false)

      # The following `vue_issues_list`/`vue_issuables_list` stubs can be removed
      # once the Vue issues page has feature parity with the current Haml page
      stub_feature_flags(vue_issues_list: false)
      stub_feature_flags(vue_issuables_list: false)

      # Disable `refactor_blob_viewer` as we refactor
      # the blob viewer. See the follwing epic for more:
      # https://gitlab.com/groups/gitlab-org/-/epics/5531
      stub_feature_flags(refactor_blob_viewer: false)

      # Disable `main_branch_over_master` as we migrate
      # from `master` to `main` accross our codebase.
      # It's done in order to preserve the concistency in tests
      # As we're ready to change `master` usages to `main`, let's enable it
      stub_feature_flags(main_branch_over_master: false)

      stub_feature_flags(issue_boards_filtered_search: false)

      # Disable issue respositioning to avoid heavy load on database when importing big projects.
      # This is only turned on when app is handling heavy project imports.
      # Can be removed when we find a better way to deal with the problem.
      # For more information check https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4321
      stub_feature_flags(block_issue_repositioning: false)

      allow(Gitlab::GitalyClient).to receive(:can_use_disk?).and_return(enable_rugged)
    else
      unstub_all_feature_flags
    end

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

    # Administrators have to re-authenticate in order to access administrative
    # functionality when application setting admin_mode is active. Any spec
    # that requires administrative access can use the tag :enable_admin_mode
    # to avoid the second auth step (provided the user is already an admin):
    #
    # context 'some test that requires admin mode', :enable_admin_mode do ... end
    #
    # Some specs do get admin mode enabled automatically (e.g. `spec/controllers/admin`).
    # In this case, specs that need to test both admin mode states can use the
    # :do_not_mock_admin_mode tag to disable auto admin mode.
    #
    # See also spec/support/helpers/admin_mode_helpers.rb
    if example.metadata[:enable_admin_mode] && !example.metadata[:do_not_mock_admin_mode]
      allow_any_instance_of(Gitlab::Auth::CurrentUserMode).to receive(:admin_mode?) do |current_user_mode|
        current_user_mode.send(:user)&.admin?
      end
    end

    # Make sure specs test by default admin mode setting on, unless forced to the opposite
    stub_application_setting(admin_mode: true) unless example.metadata[:do_not_mock_admin_mode_setting]

    allow(Gitlab::CurrentSettings).to receive(:current_application_settings?).and_return(false)
  end

  config.around(:example, :quarantine) do |example|
    # Skip tests in quarantine unless we explicitly focus on them.
    example.run if config.inclusion_filter[:quarantine]
  end

  config.around(:example, :request_store) do |example|
    Gitlab::WithRequestStore.with_request_store { example.run }
  end

  # previous test runs may have left some resources throttled
  config.before do
    ::Gitlab::ExclusiveLease.reset_all!("el:throttle:*")
  end

  config.before(:example, :assume_throttled) do |example|
    allow(::Gitlab::ExclusiveLease).to receive(:throttle).and_return(nil)
  end

  config.before(:example, :request_store) do
    # Clear request store before actually starting the spec (the
    # `around` above will have the request store enabled for all
    # `before` blocks)
    RequestStore.clear!
  end

  config.around do |example|
    # Wrap each example in it's own context to make sure the contexts don't
    # leak
    Gitlab::ApplicationContext.with_raw_context { example.run }
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

    # Re-enable query limiting in case it was disabled
    Gitlab::QueryLimiting.enable!
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

  # Allows stdout to be redirected to reduce noise
  config.before(:each, :silence_stdout) do
    $stdout = StringIO.new
  end

  config.after(:each, :silence_stdout) do
    $stdout = STDOUT
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

# Initialize FactoryDefault to use create_default helper
TestProf::FactoryDefault.init
