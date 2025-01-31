# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('fast_spec_helper.rb', __dir__))
  warn 'Detected fast_spec_helper is loaded first than spec_helper.'
  warn 'If running test files using both spec_helper and fast_spec_helper,'
  warn 'make sure spec_helper is loaded first, or run rspec with `-r spec_helper`.'
  abort 'Aborting...'
end

require './spec/deprecation_warnings'

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

require_relative '../config/environment'

require 'rspec/mocks'
require 'rspec/rails'
require 'rspec/retry'
require 'rspec-parameterized'
require 'shoulda/matchers'
require 'test_prof/recipes/rspec/let_it_be'
require 'test_prof/factory_default'
require 'test_prof/factory_prof/nate_heckler'
require 'parslet/rig/rspec'
require 'axe-rspec'

require 'gitlab/rspec_flaky'

rspec_profiling_is_configured =
  ENV['RSPEC_PROFILING_POSTGRES_URL'].present? ||
  ENV['RSPEC_PROFILING']
branch_can_be_profiled =
  (ENV['CI_COMMIT_REF_NAME'] == 'master' ||
    ENV['CI_COMMIT_REF_NAME']&.include?('rspec-profile'))

if rspec_profiling_is_configured && (!ENV.key?('CI') || branch_can_be_profiled)
  require 'rspec_profiling/rspec'
end

Rainbow.enabled = false

# Enable zero monkey patching mode before loading any other RSpec code.
RSpec.configure(&:disable_monkey_patching!)

require_relative('../ee/spec/spec_helper') if Gitlab.ee?
require_relative('../jh/spec/spec_helper') if Gitlab.jh?

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Requires helpers, and shared contexts/examples first since they're used in other support files

# Load these first since they may be required by other helpers
require Rails.root.join("spec/support/helpers/stub_requests.rb")

# Then the rest
Dir[Rails.root.join("spec/support/helpers/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/shared_contexts/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/shared_examples/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

require_relative '../tooling/quality/test_level'

quality_level = Quality::TestLevel.new

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false

  if ::Gitlab.next_rails?
    config.fixture_paths = [Rails.root]
  else
    config.fixture_path = Rails.root
  end

  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.infer_spec_type_from_file_location!

  # Add :full_backtrace tag to an example if full_backtrace output is desired
  config.before(:each, :full_backtrace) do |example|
    config.full_backtrace = true
  end

  # Attempt to troubleshoot  https://gitlab.com/gitlab-org/gitlab/-/issues/351531
  config.after do |example|
    if example.exception.is_a?(Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError)
      ::CrossDatabaseModification::TransactionStackTrackRecord.log_gitlab_transactions_stack(action: :after_failure, example: example.description)
    else
      ::CrossDatabaseModification::TransactionStackTrackRecord.log_gitlab_transactions_stack(action: :after_example, example: example.description)
    end
  end

  config.after do |example|
    # We fail early if we detect a PG::QueryCanceled error
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/402915
    if example.exception && example.exception.message.include?('PG::QueryCanceled')
      ENV['RSPEC_BYPASS_SYSTEM_EXIT_PROTECTION'] = 'true'

      warn
      warn "********************************************************************************************"
      warn "********************************************************************************************"
      warn "********************************************************************************************"
      warn "*                                                                                          *"
      warn "* We have detected a PG::QueryCanceled error in the specs, so we're failing early.         *"
      warn "* Please retry this job.                                                                   *"
      warn "*                                                                                          *"
      warn "* See https://gitlab.com/gitlab-org/gitlab/-/issues/402915 for more info.                  *"
      warn "*                                                                                          *"
      warn "********************************************************************************************"
      warn "********************************************************************************************"
      warn "********************************************************************************************"
      warn

      exit 3
    end
  end

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_spec\.rb\z}) do |metadata|
    location = metadata[:location]

    metadata[:level] = quality_level.level_for(location)
    metadata[:api] = true if location.include?('/spec/requests/api/')

    # Do not overwrite migration if it's already set
    unless metadata.key?(:migration)
      metadata[:migration] = true if metadata[:level] == :migration || metadata[:level] == :background_migration
    end

    # Admin controller specs get auto admin mode enabled since they are
    # protected by the 'EnforcesAdminAuthentication' concern
    metadata[:enable_admin_mode] = true if %r{(ee)?/spec/controllers/admin/}.match?(location)

    # The worker specs get Sidekiq context
    metadata[:with_sidekiq_context] = true if %r{(ee)?/spec/workers/}.match?(location)
  end

  config.define_derived_metadata(file_path: %r{(ee)?/spec/.+_docs\.rb\z}) do |metadata|
    metadata[:type] = :feature
  end

  config.define_derived_metadata(file_path: %r{spec/dot_gitlab_ci/ci_configuration_validation/}) do |metadata|
    metadata[:ci_config_validation] = true
  end

  config.include LicenseHelpers
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include FactoryBot::Syntax::Methods
  config.include FixtureHelpers
  config.include NonExistingRecordsHelpers
  config.include GitlabRoutingHelper
  config.include StubGitlabCalls
  config.include NextFoundInstanceOf
  config.include NextInstanceOf
  config.include FileReadHelpers
  config.include Database::MultipleDatabasesHelpers
  config.include Database::WithoutCheckConstraint
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include SignUpHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include WaitHelpers, type: :feature
  config.include WaitForRequests, type: :feature
  config.include Features::DomHelpers, type: :feature
  config.include TestidHelpers, type: :feature
  config.include TestidHelpers, type: :component
  config.include Features::HighlightContentHelper, type: :feature
  config.include EmailHelpers, :mailer, type: :mailer
  config.include Warden::Test::Helpers, type: :request
  config.include Gitlab::Routing, type: :routing
  config.include ApiHelpers, :api
  config.include CookieHelper, :js
  config.include SelectionHelper, :js
  config.include InspectRequests, :js
  config.include LiveDebugger, :js
  config.include MigrationsHelpers, :migration
  config.include RedisHelpers
  config.include Rails.application.routes.url_helpers, type: :routing
  config.include Rails.application.routes.url_helpers, type: :component
  config.include Rails.application.routes.url_helpers, type: :presenter
  config.include PolicyHelpers, type: :policy
  config.include ExpectRequestWithStatus, type: :request
  config.include IdempotentWorkerHelper, type: :worker
  config.include RailsHelpers
  config.include SidekiqMiddleware
  config.include StubActionCableConnection, type: :channel
  config.include StubMemberAccessLevel
  config.include SnowplowHelpers
  config.include RenderedHelpers
  config.include RSpec::Benchmark::Matchers, type: :benchmark
  config.include DetailedErrorHelpers
  config.include RequestUrgencyMatcher, type: :controller
  config.include RequestUrgencyMatcher, type: :request
  config.include Capybara::RSpecMatchers, type: :request
  config.include PendingDirectUploadHelpers, :direct_uploads
  config.include LabelsHelper, type: :feature
  config.include UnlockPipelinesHelpers, :unlock_pipelines
  config.include UserWithNamespaceShim
  config.include OrphanFinalArtifactsCleanupHelpers, :orphan_final_artifacts_cleanup
  config.include ClickHouseHelpers, :click_house
  config.include WorkItems::DataSync::AssociationsHelpers

  config.include_context 'when rendered has no HTML escapes', type: :view

  include StubFeatureFlags
  include StubSnowplow
  include StubMember

  if ENV['CI'] || ENV['RETRIES']
    # Gradually stop using rspec-retry
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/438388
    config.default_retry_count = 1
    config.prepend_before(:each, type: :feature) do |example|
      # This includes the first try, i.e. tests will be run 2 times before failing.
      example.metadata[:retry] = ENV.fetch('RETRIES', 1).to_i + 1
    end

    config.exceptions_to_hard_fail = [DeprecationToolkitEnv::DeprecationBehaviors::SelectiveRaise::RaiseDisallowedDeprecation]
  end

  if Gitlab::RspecFlaky::Config.generate_report?
    config.reporter.register_listener(
      Gitlab::RspecFlaky::Listener.new,
      :example_passed,
      :dump_summary)
  end

  config.before(:suite) do
    TestEnv.init

    # Reload all feature flags definitions
    Feature.register_definitions

    # Enable all features by default for testing
    # Reset any changes in after hook.
    stub_all_feature_flags
    stub_feature_flags(main_branch_over_master: false)

    TestEnv.seed_db
  end

  config.after(:all) do
    TestEnv.clean_test_path
  end

  # We can't use an `around` hook here because the wrapping transaction
  # is not yet opened at the time that is triggered
  config.prepend_before do
    ApplicationRecord.set_open_transactions_baseline
    ::Ci::ApplicationRecord.set_open_transactions_baseline
  end

  config.around do |example|
    example.run
  end

  config.append_after do
    ApplicationRecord.reset_open_transactions_baseline
    ::Ci::ApplicationRecord.reset_open_transactions_baseline
  end

  config.before do |example|
    if example.metadata.fetch(:stub_feature_flags, true)
      # The following can be removed when we remove the staged rollout strategy
      # and we can just enable it using instance wide settings
      # (ie. ApplicationSetting#auto_devops_enabled)
      stub_feature_flags(force_autodevops_on_by_default: false)

      # The survey popover can block the diffs causing specs to fail
      stub_feature_flags(mr_experience_survey: false)

      # Using FortiAuthenticator as OTP provider is disabled by default in
      # tests, until we introduce it in user settings
      stub_feature_flags(forti_authenticator: false)

      # Using FortiToken Cloud as OTP provider is disabled by default in
      # tests, until we introduce it in user settings
      stub_feature_flags(forti_token_cloud: false)

      # These feature flag are by default disabled and used in disaster recovery mode
      stub_feature_flags(ci_queueing_disaster_recovery_disable_fair_scheduling: false)
      stub_feature_flags(ci_queueing_disaster_recovery_disable_quota: false)
      stub_feature_flags(ci_queuing_disaster_recovery_disable_allowed_plans: false)

      # It's disabled in specs because we don't support certain features which
      # cause spec failures.
      stub_feature_flags(gitlab_error_tracking: false)

      # Disable this to avoid the Web IDE modals popping up in tests:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/385453
      stub_feature_flags(vscode_web_ide: false)

      # Disable `main_branch_over_master` as we migrate
      # from `master` to `main` accross our codebase.
      # It's done in order to preserve the concistency in tests
      # As we're ready to change `master` usages to `main`, let's enable it
      stub_feature_flags(main_branch_over_master: false)

      # Disable issue respositioning to avoid heavy load on database when importing big projects.
      # This is only turned on when app is handling heavy project imports.
      # Can be removed when we find a better way to deal with the problem.
      # For more information check https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4321
      stub_feature_flags(block_issue_repositioning: false)

      # These are ops feature flags that are disabled by default
      stub_feature_flags(disable_anonymous_project_search: false)
      stub_feature_flags(disable_cancel_redundant_pipelines_service: false)

      # Specs should not require email verification by default, this makes the sign-in flow simpler in
      # most cases. We do test the email verification flow in the appropriate specs.
      stub_feature_flags(require_email_verification: false)

      # Keep-around refs should only be turned off for specific projects/repositories.
      stub_feature_flags(disable_keep_around_refs: false)

      # Disable suspending ClickHouse data ingestion workers
      stub_feature_flags(suspend_click_house_data_ingestion: false)

      # Experimental merge request dashboard
      stub_feature_flags(merge_request_dashboard: false)

      # This feature flag allows enabling self-hosted features on Staging Ref: https://gitlab.com/gitlab-org/gitlab/-/issues/497784
      stub_feature_flags(allow_self_hosted_features_for_com: false)

      # we need the `cleanup_data_source_work_item_data` disabled by default to prevent deletion of some data
      stub_feature_flags(cleanup_data_source_work_item_data: false)
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

    # Ensure that Snowplow is enabled by default unless forced to the opposite
    stub_snowplow unless example.metadata[:do_not_stub_snowplow_by_default]
  end

  config.around(:example, :quarantine) do |example|
    # Skip tests in quarantine unless we explicitly focus on them or not in CI
    example.run if config.inclusion_filter[:quarantine] || !ENV['CI']
  end

  config.around(:example, :ci_config_validation) do |example|
    # Skip tests for ci config validation unless we explicitly focus on them or not in CI
    example.run if config.inclusion_filter[:ci_config_validation] || !ENV['CI']
  end

  config.around(:example, :request_store) do |example|
    ::Gitlab::SafeRequestStore.ensure_request_store { example.run }
  end

  config.around do |example|
    ::Gitlab::Ci::Config::FeatureFlags.ensure_correct_usage do
      example.run
    end
  end

  config.around(:example, :allow_unrouted_sidekiq_calls) do |example|
    ::Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      example.run
    end
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
        skip_jobs: false # We're not skipping jobs for inline tests
      ).call(chain)

      chain.insert_after ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware, IsolatedRequestStore

      example.run
    end
  end

  config.around do |example|
    Gitlab::SidekiqSharding::Validator.enabled do
      example.run
    end
  end

  config.after do
    Fog.unmock! if Fog.mock?
    Gitlab::ApplicationSettingFetcher.clear_in_memory_application_settings!

    # Reset all feature flag stubs to default for testing
    stub_all_feature_flags

    # Re-enable query limiting in case it was disabled
    Gitlab::QueryLimiting.enable!

    # Reset ActiveSupport::CurrentAttributes models
    ActiveSupport::CurrentAttributes.reset_all
  end

  config.before(:example, :mailer) do
    reset_delivered_emails!
  end

  config.before(:example, :prometheus) do
    matching_files = File.join(::Prometheus::Client.configuration.multiprocess_files_dir, "**/*.db")
    Dir[matching_files].map { |filename| File.delete(filename) if File.file?(filename) }

    Gitlab::Metrics.reset_registry!
  end

  config.before(:example, :eager_load) do
    Rails.application.eager_load!
  end

  # This makes sure the `ApplicationController#can?` method is stubbed with the
  # original implementation for all view specs.
  config.before(:each, type: :view) do
    allow(view).to receive(:can?) do |*args|
      Ability.allowed?(*args)
    end
  end

  # Ensures that any Javascript script that tries to make the external VersionCheck API call skips it and returns a response
  config.before(:each, :js) do
    allow_any_instance_of(VersionCheck).to receive(:response).and_return({ "severity" => "success" })
  end

  [:migration, :delete].each do |spec_type|
    message = <<~STRING
      We detected an open transaction before running the example. This is not allowed with specs that rely on a table
      deletion strategy like those marked as `:#{spec_type}`.

      A common scenario for this is using `test-prof` methods in your specs. `let_it_be` and `before_all` methods open
      a transaction before all the specs in a context are run, and this is not compatible with these type of specs.
      Consider replacing these methods with `let!` and `before(:all)`.

      For more information see
      https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#testprof-in-migration-specs
    STRING

    config.around(:each, spec_type) do |example|
      next example.run if example.metadata[:migration_with_transaction]

      self.class.use_transactional_tests = false

      if DbCleaner.all_connection_classes.any? { |klass| klass.connection.transaction_open? }
        raise message
      end

      example.run

      delete_from_all_tables!(except: deletion_except_tables)

      self.class.use_transactional_tests = true
    end
  end

  config.before(:context) do
    # Clear support bot user memoization because it's created
    # a lot of times in our test suite and ids mighht not match any more.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.clear_memoization(:support_bot_id)
  end
end

# Disabled because it's causing N+1 queries.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/396352.
# Support::AbilityCheck.inject(Ability.singleton_class)
Support::PermissionsCheck.inject(Ability.singleton_class)

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

# Set the start of ID sequence for records initialized by `build_stubbed` to prevent conflicts
FactoryBot::Strategy::Stub.next_id = 1_000_000_000

# Exclude the Geo proxy API request from getting on_next_request Warden handlers,
# necessary to prevent race conditions with feature tests not getting authenticated.
::Warden.asset_paths << %r{^/api/v4/geo/proxy$}

module TouchRackUploadedFile
  def initialize_from_file_path(path)
    super

    # This is a no-op workaround for https://github.com/docker/for-linux/issues/1015
    File.utime @tempfile.atime, @tempfile.mtime, @tempfile.path # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end

Rack::Test::UploadedFile.prepend(TouchRackUploadedFile)

# Inject middleware to enable ActiveSupport::Notifications for Redis commands
module RedisCommands
  module Instrumentation
    def call(command, redis_config)
      ActiveSupport::Notifications.instrument('redis.process_commands', commands: command) do
        super(command, redis_config)
      end
    end
  end
end

RedisClient.register(RedisCommands::Instrumentation)

module UsersInternalAllowExclusiveLease
  extend ActiveSupport::Concern

  class_methods do
    def unique_internal(scope, username, email_pattern, &block)
      # this lets skip transaction checks when Users::Internal bots are created in
      # let_it_be blocks during test set-up.
      #
      # Users::Internal bot creation within examples are still checked since the RSPec.current_scope is :example
      if ::RSpec.respond_to?(:current_scope) && ::RSpec.current_scope == :before_all
        Gitlab::ExclusiveLease.skipping_transaction_check { super }
      else
        super
      end
    end

    # TODO: Until https://gitlab.com/gitlab-org/gitlab/-/issues/442780 is resolved we're creating internal users in the
    # first organization as a temporary workaround. Many specs lack an organization in the database, causing foreign key
    # constraint violations when creating internal users. We're not seeding organizations before all specs for
    # performance.
    def create_unique_internal(scope, username, email_pattern, &creation_block)
      Organizations::Organization.first || FactoryBot.create(:organization)

      super
    end
  end
end

Users::Internal.prepend(UsersInternalAllowExclusiveLease)
