# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSetting, feature_category: :shared, type: :model do
  using RSpec::Parameterized::TableSyntax

  subject(:setting) { described_class.create_from_defaults }

  it_behaves_like 'sanitizable', :application_setting, %i[default_branch_name]

  it { expect(described_class).to include(CacheableAttributes) }
  it { expect(described_class).to include(ApplicationSettingImplementation) }
  it { expect(described_class.current_without_cache).to eq(described_class.last) }

  it { expect(setting).to be_valid }
  it { expect(setting.uuid).to be_present }
  it { expect(setting).to have_db_column(:auto_devops_enabled) }

  describe 'default values' do
    subject(:setting) { described_class.new }

    it { expect(setting.id).to eq(1) }
    it { expect(setting.repository_storages_weighted).to eq({}) }
    it { expect(setting.kroki_formats).to eq({}) }
    it { expect(setting.default_branch_protection_defaults).to eq({}) }
    it { expect(setting.max_decompressed_archive_size).to eq(25600) }
    it { expect(setting.decompress_archive_file_timeout).to eq(210) }
    it { expect(setting.bulk_import_concurrent_pipeline_batch_limit).to eq(25) }
    it { expect(setting.allow_project_creation_for_guest_and_below).to be(true) }
    it { expect(setting.members_delete_limit).to eq(60) }
    it { expect(setting.downstream_pipeline_trigger_limit_per_project_user_sha).to eq(0) }
    it { expect(setting.asciidoc_max_includes).to eq(32) }
    it { expect(setting.concurrent_github_import_jobs_limit).to eq(1000) }
    it { expect(setting.concurrent_bitbucket_import_jobs_limit).to eq(100) }
    it { expect(setting.concurrent_bitbucket_server_import_jobs_limit).to eq(100) }
    it { expect(setting.nuget_skip_metadata_url_validation).to be(false) }
    it { expect(setting.silent_admin_exports_enabled).to be(false) }
    it { expect(setting.group_api_limit).to eq(400) }
    it { expect(setting.group_invited_groups_api_limit).to eq(60) }
    it { expect(setting.group_projects_api_limit).to eq(600) }
    it { expect(setting.group_shared_groups_api_limit).to eq(60) }
    it { expect(setting.groups_api_limit).to eq(200) }
    it { expect(setting.create_organization_api_limit).to eq(10) }
    it { expect(setting.project_api_limit).to eq(400) }
    it { expect(setting.project_invited_groups_api_limit).to eq(60) }
    it { expect(setting.projects_api_limit).to eq(2000) }
    it { expect(setting.user_contributed_projects_api_limit).to eq(100) }
    it { expect(setting.user_projects_api_limit).to eq(300) }
    it { expect(setting.user_starred_projects_api_limit).to eq(100) }
    it { expect(setting.disable_password_authentication_for_users_with_sso_identities).to be(false) }
    it { expect(setting.root_moved_permanently_redirection).to be(false) }
    it { expect(setting.resource_usage_limits).to eq({}) }
    it { expect(setting.resource_access_token_notify_inherited).to be(false) }
    it { expect(setting.lock_resource_access_token_notify_inherited).to be(false) }
    it { expect(setting.ropc_without_client_credentials).to be(true) }
    it { expect(setting.global_search_issues_enabled).to be(true) }
    it { expect(setting.global_search_merge_requests_enabled).to be(true) }
    it { expect(setting.global_search_snippet_titles_enabled).to be(true) }
    it { expect(setting.global_search_users_enabled).to be(true) }
  end

  describe 'USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS' do
    subject { described_class::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS }

    it { is_expected.to eq(3) }
  end

  describe 'INACTIVE_RESOURCE_ACCESS_TOKENS_DELETE_AFTER_DAYS' do
    subject { described_class::INACTIVE_RESOURCE_ACCESS_TOKENS_DELETE_AFTER_DAYS }

    it { is_expected.to eq(30) }
  end

  describe 'validations' do
    let(:http)  { 'http://example.com' }
    let(:https) { 'https://example.com' }
    let(:ftp)   { 'ftp://example.com' }
    let(:javascript) { 'javascript:alert(window.opener.document.location)' }

    let_it_be(:valid_prometheus_alert_db_indicators_settings) do
      {
        prometheus_api_url: 'Prometheus URL',
        apdex_sli_query: {
          main: 'Apdex SLI query main',
          ci: 'Apdex SLI query ci'
        },
        apdex_slo: {
          main: 0.99,
          ci: 0.98
        },
        wal_rate_sli_query: {
          main: 'WAL rate query main',
          ci: 'WAL rate query ci'
        },
        wal_rate_slo: {
          main: 7000,
          ci: 7000
        }
      }
    end

    it { expect(described_class).to validate_jsonb_schema(['application_setting_search']) }
    it { expect(described_class).to validate_jsonb_schema(['resource_usage_limits']) }
    it { expect(described_class).to validate_jsonb_schema(['application_setting_rate_limits']) }
    it { expect(described_class).to validate_jsonb_schema(['application_setting_package_registry']) }
    it { expect(described_class).to validate_jsonb_schema(['application_setting_service_ping_settings']) }
    it { expect(described_class).to validate_jsonb_schema(['application_setting_sign_in_restrictions']) }
    it { expect(described_class).to validate_jsonb_schema(['application_setting_transactional_emails']) }

    it { is_expected.to allow_value(nil).for(:home_page_url) }
    it { is_expected.to allow_value(http).for(:home_page_url) }
    it { is_expected.to allow_value(https).for(:home_page_url) }
    it { is_expected.not_to allow_value(ftp).for(:home_page_url) }

    it { is_expected.to allow_value(nil).for(:after_sign_out_path) }
    it { is_expected.to allow_value(http).for(:after_sign_out_path) }
    it { is_expected.to allow_value(https).for(:after_sign_out_path) }
    it { is_expected.not_to allow_value(ftp).for(:after_sign_out_path) }

    it { is_expected.to allow_value("dev.gitlab.com").for(:commit_email_hostname) }
    it { is_expected.not_to allow_value("@dev.gitlab").for(:commit_email_hostname) }

    it { is_expected.to allow_value("myemail@gitlab.com").for(:lets_encrypt_notification_email) }
    it { is_expected.to allow_value(nil).for(:lets_encrypt_notification_email) }
    it { is_expected.not_to allow_value("notanemail").for(:lets_encrypt_notification_email) }
    it { is_expected.not_to allow_value("myemail@example.com").for(:lets_encrypt_notification_email) }
    it { is_expected.to allow_value("myemail@test.example.com").for(:lets_encrypt_notification_email) }

    it { is_expected.to allow_value(['192.168.1.1'] * 1_000).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['192.168.1.1'] * 1_001).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['1' * 255]).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['1' * 256]).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['ğitlab.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['xn--itlab-j1a.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['<h1></h1>']).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['gitlab.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(nil).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value([]).for(:outbound_local_requests_whitelist) }

    it { is_expected.to allow_value(nil).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(http).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(https).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(['/example'] * 100).for(:protected_paths) }
    it { is_expected.not_to allow_value(['/example'] * 101).for(:protected_paths) }
    it { is_expected.not_to allow_value(nil).for(:protected_paths) }
    it { is_expected.to allow_value([]).for(:protected_paths) }
    it { is_expected.to allow_value(['/example'] * 100).for(:protected_paths_for_get_request) }
    it { is_expected.not_to allow_value(['/example'] * 101).for(:protected_paths_for_get_request) }
    it { is_expected.not_to allow_value(nil).for(:protected_paths_for_get_request) }
    it { is_expected.to allow_value([]).for(:protected_paths_for_get_request) }

    it do
      is_expected.to validate_numericality_of(:wiki_page_max_content_bytes)
        .only_integer.is_greater_than_or_equal_to(1024)
    end

    it { is_expected.to validate_presence_of(:max_pages_size) }

    it 'ensures max_pages_size is an integer greater than 0 (or equal to 0 to indicate unlimited/maximum)' do
      is_expected.to validate_numericality_of(:max_pages_size).only_integer.is_greater_than_or_equal_to(0)
                       .is_less_than(::Gitlab::Pages::MAX_SIZE / 1.megabyte)
    end

    it { is_expected.not_to allow_value(7).for(:minimum_password_length) }
    it { is_expected.not_to allow_value(129).for(:minimum_password_length) }
    it { is_expected.not_to allow_value(nil).for(:minimum_password_length) }
    it { is_expected.not_to allow_value('abc').for(:minimum_password_length) }
    it { is_expected.to allow_value(10).for(:minimum_password_length) }

    it { is_expected.not_to allow_value(false).for(:hashed_storage_enabled) }

    it { is_expected.to allow_value('default' => 0).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => 50).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => 100).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => '90').for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => nil).for(:repository_storages_weighted) }

    it do
      is_expected.not_to allow_value('default' => -1).for(:repository_storages_weighted)
        .with_message("value for 'default' must be between 0 and 100")
    end

    it do
      is_expected.not_to allow_value('default' => 101).for(:repository_storages_weighted)
        .with_message("value for 'default' must be between 0 and 100")
    end

    it do
      is_expected.not_to allow_value('default' => 100,
        shouldntexist: 50).for(:repository_storages_weighted).with_message("can't include: shouldntexist")
    end

    def many_usernames(num = 100)
      Array.new(num) { |i| "username#{i}" }
    end

    it { is_expected.to allow_value(many_usernames(100)).for(:notes_create_limit_allowlist) }
    it { is_expected.not_to allow_value(many_usernames(101)).for(:notes_create_limit_allowlist) }
    it { is_expected.not_to allow_value(nil).for(:notes_create_limit_allowlist) }
    it { is_expected.to allow_value([]).for(:notes_create_limit_allowlist) }

    it { is_expected.to allow_value(many_usernames(100)).for(:users_get_by_id_limit_allowlist) }
    it { is_expected.not_to allow_value(many_usernames(101)).for(:users_get_by_id_limit_allowlist) }
    it { is_expected.not_to allow_value(nil).for(:users_get_by_id_limit_allowlist) }
    it { is_expected.to allow_value([]).for(:users_get_by_id_limit_allowlist) }

    it { is_expected.to allow_value(many_usernames(100)).for(:search_rate_limit_allowlist) }
    it { is_expected.not_to allow_value(many_usernames(101)).for(:search_rate_limit_allowlist) }
    it { is_expected.not_to allow_value(nil).for(:search_rate_limit_allowlist) }
    it { is_expected.to allow_value([]).for(:search_rate_limit_allowlist) }

    it { is_expected.to allow_value('all_tiers').for(:whats_new_variant) }
    it { is_expected.to allow_value('current_tier').for(:whats_new_variant) }
    it { is_expected.to allow_value('disabled').for(:whats_new_variant) }
    it { is_expected.not_to allow_value(nil).for(:whats_new_variant) }

    it { is_expected.to allow_value('http://example.com/').for(:public_runner_releases_url) }
    it { is_expected.not_to allow_value(nil).for(:public_runner_releases_url) }

    it { is_expected.not_to allow_value(['']).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(['OBVIOUSLY_WRONG']).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(%w[project project]).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value([nil]).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(nil).for(:valid_runner_registrars) }
    it { is_expected.to allow_value([]).for(:valid_runner_registrars) }
    it { is_expected.to allow_value(%w[project group]).for(:valid_runner_registrars) }

    it { is_expected.to allow_value(http).for(:jira_connect_proxy_url) }
    it { is_expected.to allow_value(https).for(:jira_connect_proxy_url) }

    it { is_expected.to allow_value(http).for(:jira_connect_additional_audience_url) }
    it { is_expected.to allow_value(https).for(:jira_connect_additional_audience_url) }

    it { is_expected.not_to allow_value(apdex_slo: '10').for(:prometheus_alert_db_indicators_settings) }
    it { is_expected.to allow_value(nil).for(:prometheus_alert_db_indicators_settings) }

    it do
      is_expected.to allow_value(valid_prometheus_alert_db_indicators_settings)
        .for(:prometheus_alert_db_indicators_settings)
    end

    it { is_expected.to allow_value(true).for(:silent_admin_exports_enabled) }
    it { is_expected.to allow_value(false).for(:silent_admin_exports_enabled) }

    it { is_expected.to allow_values([true, false]).for(:enforce_ci_inbound_job_token_scope_enabled) }
    it { is_expected.not_to allow_value(nil).for(:enforce_ci_inbound_job_token_scope_enabled) }

    context 'for non-null integer attributes starting from 0' do
      where(:attribute) do
        %i[
          bulk_import_max_download_file_size
          ci_max_includes
          ci_max_total_yaml_size_bytes
          container_registry_cleanup_tags_service_max_list_size
          container_registry_data_repair_detail_worker_max_concurrency
          container_registry_delete_tags_service_timeout
          container_registry_expiration_policies_worker_capacity
          decompress_archive_file_timeout
          dependency_proxy_ttl_group_policy_worker_capacity
          downstream_pipeline_trigger_limit_per_project_user_sha
          gitlab_shell_operation_limit
          group_api_limit
          group_projects_api_limit
          group_shared_groups_api_limit
          groups_api_limit
          inactive_projects_min_size_mb
          issues_create_limit
          jobs_per_stage_page_size
          max_decompressed_archive_size
          max_export_size
          max_import_remote_file_size
          max_import_size
          max_pages_custom_domains_per_project
          max_terraform_state_size_bytes
          members_delete_limit
          notes_create_limit
          pages_extra_deployments_default_expiry_seconds
          package_registry_cleanup_policies_worker_capacity
          packages_cleanup_package_file_worker_capacity
          pipeline_limit_per_project_user_sha
          create_organization_api_limit
          project_api_limit
          projects_api_limit
          projects_api_rate_limit_unauthenticated
          raw_blob_request_limit
          search_rate_limit
          search_rate_limit_unauthenticated
          sidekiq_job_limiter_compression_threshold_bytes
          sidekiq_job_limiter_limit_bytes
          terminal_max_session_time
          user_contributed_projects_api_limit
          user_projects_api_limit
          user_starred_projects_api_limit
          users_get_by_id_limit
        ]
      end

      with_them do
        it { is_expected.to validate_numericality_of(attribute).only_integer.is_greater_than_or_equal_to(0) }
        it { is_expected.not_to allow_value(nil).for(attribute) }
      end
    end

    context 'for non-null numerical attributes starting from 0' do
      where(:attribute) do
        %i[
          push_event_hooks_limit
          push_event_activities_limit
        ]
      end

      with_them do
        it { is_expected.to validate_numericality_of(attribute).is_greater_than_or_equal_to(0) }
        it { is_expected.not_to allow_value(nil).for(attribute) }
      end
    end

    context 'for non-null integer attributes starting from 1' do
      where(:attribute) do
        %i[
          bulk_import_concurrent_pipeline_batch_limit
          code_suggestions_api_rate_limit
          concurrent_bitbucket_import_jobs_limit
          concurrent_bitbucket_server_import_jobs_limit
          concurrent_github_import_jobs_limit
          container_registry_token_expire_delay
          housekeeping_optimize_repository_period
          max_artifacts_size
          max_artifacts_content_include_size
          max_attachment_size
          max_yaml_depth
          max_yaml_size_bytes
          namespace_aggregation_schedule_lease_duration_in_seconds
          project_jobs_api_rate_limit
          session_expire_delay
          snippet_size_limit
          throttle_authenticated_api_period_in_seconds
          throttle_authenticated_api_requests_per_period
          throttle_authenticated_deprecated_api_period_in_seconds
          throttle_authenticated_deprecated_api_requests_per_period
          throttle_authenticated_files_api_period_in_seconds
          throttle_authenticated_files_api_requests_per_period
          throttle_authenticated_git_lfs_period_in_seconds
          throttle_authenticated_git_lfs_requests_per_period
          throttle_authenticated_packages_api_period_in_seconds
          throttle_authenticated_packages_api_requests_per_period
          throttle_authenticated_web_period_in_seconds
          throttle_authenticated_web_requests_per_period
          throttle_protected_paths_period_in_seconds
          throttle_protected_paths_requests_per_period
          throttle_unauthenticated_api_period_in_seconds
          throttle_unauthenticated_api_requests_per_period
          throttle_unauthenticated_deprecated_api_period_in_seconds
          throttle_unauthenticated_deprecated_api_requests_per_period
          throttle_unauthenticated_files_api_period_in_seconds
          throttle_unauthenticated_files_api_requests_per_period
          throttle_unauthenticated_git_http_period_in_seconds
          throttle_unauthenticated_git_http_requests_per_period
          throttle_unauthenticated_packages_api_period_in_seconds
          throttle_unauthenticated_packages_api_requests_per_period
          throttle_unauthenticated_period_in_seconds
          throttle_unauthenticated_requests_per_period
        ]
      end

      with_them do
        it { is_expected.to validate_numericality_of(attribute).only_integer.is_greater_than(0) }
        it { is_expected.not_to allow_value(nil).for(attribute) }
      end
    end

    context 'for null integer attributes starting from 1' do
      where(:attribute) do
        %i[
          failed_login_attempts_unlock_period_in_minutes
          external_pipeline_validation_service_timeout
          max_login_attempts
        ]
      end

      with_them do
        it { is_expected.to validate_numericality_of(attribute).only_integer.is_greater_than(0).allow_nil }
      end
    end

    it { is_expected.not_to allow_value(nil).for(:math_rendering_limits_enabled) }

    context 'when deactivate_dormant_users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
      end

      it { is_expected.not_to allow_value(nil).for(:deactivate_dormant_users_period) }
      it { is_expected.to allow_value(90).for(:deactivate_dormant_users_period) }
      it { is_expected.to allow_value(365).for(:deactivate_dormant_users_period) }
      it { is_expected.not_to allow_value(89).for(:deactivate_dormant_users_period) }
    end

    context 'for help_page_documentation_base_url validations' do
      it { is_expected.to allow_value(nil).for(:help_page_documentation_base_url) }
      it { is_expected.to allow_value('https://docs.gitlab.com').for(:help_page_documentation_base_url) }
      it { is_expected.to allow_value('http://127.0.0.1').for(:help_page_documentation_base_url) }
      it { is_expected.not_to allow_value('docs.gitlab.com').for(:help_page_documentation_base_url) }

      context 'when url length validation' do
        let(:value) { 'http://'.ljust(length, 'A') }

        context 'when value string length is 255 characters' do
          let(:length) { 255 }

          it 'allows the value' do
            is_expected.to allow_value(value).for(:help_page_documentation_base_url)
          end
        end

        context 'when value string length exceeds 255 characters' do
          let(:length) { 256 }

          it 'does not allow the value' do
            is_expected.not_to allow_value(value)
                                 .for(:help_page_documentation_base_url)
                                 .with_message('is too long (maximum is 255 characters)')
          end
        end
      end
    end

    context 'for grafana_url validations' do
      before do
        subject.instance_variable_set(:@parsed_grafana_url, nil)
      end

      it { is_expected.to allow_value(http).for(:grafana_url) }
      it { is_expected.to allow_value(https).for(:grafana_url) }
      it { is_expected.not_to allow_value(ftp).for(:grafana_url) }
      it { is_expected.not_to allow_value(javascript).for(:grafana_url) }
      it { is_expected.to allow_value('/-/grafana').for(:grafana_url) }
      it { is_expected.to allow_value('http://localhost:9000').for(:grafana_url) }

      context 'when local URLs are not allowed in system hooks' do
        before do
          stub_application_setting(allow_local_requests_from_system_hooks: false)
        end

        it { is_expected.not_to allow_value('http://localhost:9000').for(:grafana_url) }
        it { is_expected.not_to allow_value('http://localhost:9000').for(:jira_connect_proxy_url) }
        it { is_expected.not_to allow_value('http://localhost:9000').for(:jira_connect_additional_audience_url) }
      end

      context 'with invalid grafana URL' do
        it 'adds an error' do
          subject.grafana_url = " #{http}"
          expect(subject.save).to be false

          expect(subject.errors[:grafana_url]).to eq(
            [
              'must be a valid relative or absolute URL. ' \
                'Please check your Grafana URL setting in ' \
                'Admin area > Settings > Metrics and profiling > Metrics - Grafana'
            ])
        end
      end

      context 'with blocked grafana URL' do
        it 'adds an error' do
          subject.grafana_url = javascript
          expect(subject.save).to be false

          expect(subject.errors[:grafana_url]).to eq(
            [
              'is blocked: Only allowed schemes are http, https. Please check your ' \
                'Grafana URL setting in ' \
                'Admin area > Settings > Metrics and profiling > Metrics - Grafana'
            ])
        end
      end
    end

    describe 'default_branch_name validations' do
      context "when javascript tags get sanitized properly" do
        it "gets sanitized properly" do
          setting.update!(default_branch_name: "hello<script>alert(1)</script>")

          expect(setting.default_branch_name).to eq('hello')
        end
      end
    end

    describe 'spam_check_endpoint' do
      context 'when spam_check_endpoint is enabled' do
        before do
          setting.spam_check_endpoint_enabled = true
        end

        it { is_expected.to allow_value('grpc://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value('tls://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('https://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('nonsense').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value(nil).for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('').for(:spam_check_endpoint_url) }
      end

      context 'when spam_check_endpoint is NOT enabled' do
        before do
          setting.spam_check_endpoint_enabled = false
        end

        it { is_expected.to allow_value('grpc://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value('tls://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('https://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('nonsense').for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value(nil).for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value('').for(:spam_check_endpoint_url) }
      end
    end

    describe 'snowplow settings', :do_not_stub_snowplow_by_default do
      context 'when snowplow is enabled' do
        before do
          setting.snowplow_enabled = true
        end

        it { is_expected.not_to allow_value(nil).for(:snowplow_collector_hostname) }
        it { is_expected.to allow_value("snowplow.gitlab.com").for(:snowplow_collector_hostname) }
        it { is_expected.to allow_value("db-snowplow.gitlab.com").for(:snowplow_database_collector_hostname) }

        it do
          is_expected.not_to allow_value("#{'a' * 256}db-snowplow.gitlab.com")
            .for(:snowplow_database_collector_hostname)
        end

        it { is_expected.not_to allow_value('/example').for(:snowplow_collector_hostname) }
      end

      context 'when snowplow is not enabled' do
        it { is_expected.to allow_value(nil).for(:snowplow_collector_hostname) }
        it { is_expected.to allow_value(nil).for(:snowplow_database_collector_hostname) }
      end
    end

    context 'when mailgun_events_enabled is enabled' do
      before do
        setting.mailgun_events_enabled = true
      end

      it { is_expected.to validate_presence_of(:mailgun_signing_key) }
      it { is_expected.to validate_length_of(:mailgun_signing_key).is_at_most(255) }
    end

    context 'when mailgun_events_enabled is not enabled' do
      it { is_expected.not_to validate_presence_of(:mailgun_signing_key) }
    end

    context "when user accepted let's encrypt terms of service" do
      it 'requires notification email when accepting terms' do
        expect do
          setting.update!(lets_encrypt_terms_of_service_accepted: true)
        end.to raise_error(ActiveRecord::RecordInvalid,
          "Validation failed: Lets encrypt notification email can't be blank")
      end

      it 'does not allow nil email' do
        setting.lets_encrypt_terms_of_service_accepted = true
        expect(setting).not_to allow_value(nil).for(:lets_encrypt_notification_email)
      end
    end

    describe 'EKS integration' do
      before do
        setting.eks_integration_enabled = eks_enabled
      end

      context 'when integration is disabled' do
        let(:eks_enabled) { false }

        it { is_expected.to allow_value(nil).for(:eks_account_id) }
        it { is_expected.to allow_value(nil).for(:eks_access_key_id) }
        it { is_expected.to allow_value(nil).for(:eks_secret_access_key) }
      end

      context 'when integration is enabled' do
        let(:eks_enabled) { true }

        it { is_expected.to allow_value('123456789012').for(:eks_account_id) }
        it { is_expected.not_to allow_value(nil).for(:eks_account_id) }
        it { is_expected.not_to allow_value('123').for(:eks_account_id) }
        it { is_expected.not_to allow_value('12345678901a').for(:eks_account_id) }

        it { is_expected.to allow_value('access-key-id-12').for(:eks_access_key_id) }
        it { is_expected.not_to allow_value('a' * 129).for(:eks_access_key_id) }
        it { is_expected.not_to allow_value('short-key').for(:eks_access_key_id) }
        it { is_expected.to allow_value(nil).for(:eks_access_key_id) }

        it { is_expected.to allow_value('secret-access-key').for(:eks_secret_access_key) }
        it { is_expected.to allow_value(nil).for(:eks_secret_access_key) }
      end

      context 'when access key is specified' do
        let(:eks_enabled) { true }

        before do
          setting.eks_access_key_id = '123456789012'
        end

        it { is_expected.to allow_value('secret-access-key').for(:eks_secret_access_key) }
        it { is_expected.not_to allow_value(nil).for(:eks_secret_access_key) }
      end
    end

    describe 'GitLab for Slack app settings' do
      before do
        setting.slack_app_enabled = slack_app_enabled
      end

      context 'when GitLab for Slack app is disabled' do
        let(:slack_app_enabled) { false }

        it { is_expected.to allow_value(nil).for(:slack_app_id) }
        it { is_expected.to allow_value(nil).for(:slack_app_secret) }
        it { is_expected.to allow_value(nil).for(:slack_app_signing_secret) }
        it { is_expected.to allow_value(nil).for(:slack_app_verification_token) }
      end

      context 'when GitLab for Slack app is enabled' do
        let(:slack_app_enabled) { true }

        it { is_expected.to allow_value('123456789a').for(:slack_app_id) }
        it { is_expected.not_to allow_value(nil).for(:slack_app_id) }

        it { is_expected.to allow_value('secret').for(:slack_app_secret) }
        it { is_expected.not_to allow_value(nil).for(:slack_app_secret) }

        it { is_expected.to allow_value('signing-secret').for(:slack_app_signing_secret) }
        it { is_expected.not_to allow_value(nil).for(:slack_app_signing_secret) }

        it { is_expected.to allow_value('token').for(:slack_app_verification_token) }
        it { is_expected.not_to allow_value(nil).for(:slack_app_verification_token) }
      end
    end

    describe 'default_artifacts_expire_in' do
      it 'sets an error if it cannot parse' do
        expect do
          setting.update!(default_artifacts_expire_in: 'a')
        end.to raise_error(ActiveRecord::RecordInvalid,
          "Validation failed: Default artifacts expire in is not a correct duration")

        expect_invalid
      end

      it 'sets an error if it is blank' do
        expect do
          setting.update!(default_artifacts_expire_in: ' ')
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Default artifacts expire in can't be blank")

        expect_invalid
      end

      it 'sets the value if it is valid' do
        setting.update!(default_artifacts_expire_in: '30 days')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('30 days')
      end

      it 'sets the value if it is 0' do
        setting.update!(default_artifacts_expire_in: '0')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('0')
      end

      def expect_invalid
        expect(setting).to be_invalid
        expect(setting.errors.messages)
          .to have_key(:default_artifacts_expire_in)
      end
    end

    it do
      is_expected.to validate_numericality_of(:local_markdown_version)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than(65536)
    end

    it do
      is_expected.to validate_numericality_of(:archive_builds_in_seconds)
        .only_integer
        .is_greater_than_or_equal_to(1.day.seconds.to_i)
        .with_message('must be at least 1 day')
    end

    describe 'usage_ping_enabled setting' do
      shared_examples 'usage ping enabled' do
        it do
          expect(setting.usage_ping_enabled).to be(true)
          expect(setting.usage_ping_enabled?).to be(true)
        end
      end

      shared_examples 'usage ping disabled' do
        it do
          expect(setting.usage_ping_enabled).to be(false)
          expect(setting.usage_ping_enabled?).to be(false)
        end
      end

      context 'when setting is in database' do
        context 'with usage_ping_enabled disabled' do
          before do
            setting.update!(usage_ping_enabled: false)
          end

          it_behaves_like 'usage ping disabled'
        end

        context 'with usage_ping_enabled enabled' do
          before do
            setting.update!(usage_ping_enabled: true)
          end

          it_behaves_like 'usage ping enabled'
        end
      end

      context 'when setting is in GitLab config' do
        context 'with usage_ping_enabled disabled' do
          before do
            allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
          end

          it_behaves_like 'usage ping disabled'
        end

        context 'with usage_ping_enabled enabled' do
          before do
            allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
          end

          it_behaves_like 'usage ping enabled'
        end
      end

      context 'when setting in database false and setting in GitLab config true' do
        before do
          setting.update!(usage_ping_enabled: false)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
        end

        it_behaves_like 'usage ping disabled'
      end

      context 'when setting database true and setting in GitLab config false' do
        before do
          setting.update!(usage_ping_enabled: true)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
        end

        it_behaves_like 'usage ping disabled'
      end

      context 'when setting database true and setting in GitLab config true' do
        before do
          setting.update!(usage_ping_enabled: true)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
        end

        it_behaves_like 'usage ping enabled'
      end
    end

    describe '#repository_storages_with_default_weight' do
      context 'with no extra storage set-up in the config file', fips_mode: false do
        it 'keeps existing key restrictions' do
          expect(setting.repository_storages_with_default_weight).to eq({ 'default' => 100 })
        end
      end

      context 'with extra storage set-up in the config file', fips_mode: false do
        before do
          stub_storage_settings({ 'default' => {}, 'custom' => {} })
        end

        it 'keeps existing key restrictions' do
          expect(setting.repository_storages_with_default_weight).to eq({ 'default' => 100, 'custom' => 0 })
        end
      end
    end

    describe 'setting validated as `addressable_url` configured with external URI' do
      before do
        # Use any property that has the `addressable_url` validation.
        setting.help_page_documentation_base_url = 'http://example.com'
      end

      it 'is valid by default' do
        expect(setting).to be_valid
      end

      it 'is invalid when unpersisted `deny_all_requests_except_allowed` property is true' do
        setting.deny_all_requests_except_allowed = true

        expect(setting).not_to be_valid
      end
    end

    context 'with key restrictions' do
      it 'does not allow all key types to be disabled' do
        Gitlab::SSHPublicKey.supported_types.each do |type|
          setting["#{type}_key_restriction"] = described_class::FORBIDDEN_KEY_VALUE
        end

        expect(setting).not_to be_valid
        expect(setting.errors.messages).to have_key(:allowed_key_types)
      end

      where(:type) do
        Gitlab::SSHPublicKey.supported_types
      end

      with_them do
        let(:field) { :"#{type}_key_restriction" }

        shared_examples 'key validations' do
          it { is_expected.to validate_presence_of(field) }
          it { is_expected.to allow_value(*KeyRestrictionValidator.supported_key_restrictions(type)).for(field) }
          it { is_expected.not_to allow_value(128).for(field) }
        end
      end
    end

    describe '#ensure_key_restrictions!' do
      context 'with non-compliant FIPS settings' do
        before do
          setting.update_columns(
            rsa_key_restriction: 1024,
            dsa_key_restriction: 0,
            ecdsa_key_restriction: 521,
            ed25519_key_restriction: -1,
            ecdsa_sk_key_restriction: 0,
            ed25519_sk_key_restriction: 0
          )
        end

        context 'in non-FIPS mode', fips_mode: false do
          it 'keeps existing key restrictions' do
            expect { setting.ensure_key_restrictions! }.not_to change { setting.valid? }
            expect(setting).to be_valid
            expect(setting.rsa_key_restriction).to eq(1024)
            expect(setting.dsa_key_restriction).to eq(0)
            expect(setting.ecdsa_key_restriction).to eq(521)
            expect(setting.ed25519_key_restriction).to eq(-1)
            expect(setting.ecdsa_sk_key_restriction).to eq(0)
            expect(setting.ed25519_sk_key_restriction).to eq(0)
          end
        end

        context 'in FIPS mode', :fips_mode do
          it 'updates key restrictions to meet FIPS compliance' do
            expect { setting.ensure_key_restrictions! }.to change { setting.valid? }.from(false).to(true)
            expect(setting.rsa_key_restriction).to eq(3072)
            expect(setting.dsa_key_restriction).to eq(-1)
            expect(setting.ecdsa_key_restriction).to eq(521)
            expect(setting.ed25519_key_restriction).to eq(-1)
            expect(setting.ecdsa_sk_key_restriction).to eq(256)
            expect(setting.ed25519_sk_key_restriction).to eq(256)
          end
        end
      end
    end

    it_behaves_like 'an object with email-formatted attributes', :abuse_notification_email do
      subject { setting }
    end

    context 'for auto_devops_domain setting' do
      context 'when auto_devops_enabled? is true' do
        before do
          setting.update!(auto_devops_enabled: true)
        end

        it 'can be blank' do
          setting.update!(auto_devops_domain: '')

          expect(setting).to be_valid
        end

        context 'with a valid value' do
          before do
            setting.update!(auto_devops_domain: 'domain.com')
          end

          it 'is valid' do
            expect(setting).to be_valid
          end
        end

        context 'with an invalid value' do
          it 'raises a validation error on update' do
            expect do
              setting.update!(auto_devops_domain: 'definitelynotahostname')
            end.to raise_error(ActiveRecord::RecordInvalid,
              "Validation failed: Auto devops domain is not a fully qualified domain name")
          end

          it 'is invalid' do
            setting.auto_devops_domain = 'definitelynotahostname'
            expect(setting).to be_invalid
          end
        end
      end
    end

    context 'when gitaly timeouts' do
      it "validates that the default_timeout is lower than the max_request_duration" do
        is_expected.to validate_numericality_of(:gitaly_timeout_default)
          .is_less_than_or_equal_to(Settings.gitlab.max_request_duration_seconds)
      end

      [:gitaly_timeout_default, :gitaly_timeout_medium, :gitaly_timeout_fast].each do |timeout_name|
        specify do
          is_expected.to validate_presence_of(timeout_name)
          is_expected.to validate_numericality_of(timeout_name).only_integer
            .is_greater_than_or_equal_to(0)
        end
      end

      [:gitaly_timeout_medium, :gitaly_timeout_fast].each do |timeout_name|
        it "validates that #{timeout_name} is lower than timeout_default" do
          subject[:gitaly_timeout_default] = 50
          subject[timeout_name] = 100

          expect(subject).to be_invalid
        end
      end

      it 'accepts all timeouts equal' do
        subject.gitaly_timeout_default = 0
        subject.gitaly_timeout_medium = 0
        subject.gitaly_timeout_fast = 0

        expect(subject).to be_valid
      end

      it 'accepts timeouts in descending order' do
        subject.gitaly_timeout_default = 50
        subject.gitaly_timeout_medium = 30
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_valid
      end

      it 'rejects timeouts in ascending order' do
        subject.gitaly_timeout_default = 20
        subject.gitaly_timeout_medium = 30
        subject.gitaly_timeout_fast = 50

        expect(subject).to be_invalid
      end

      it 'rejects medium timeout larger than default' do
        subject.gitaly_timeout_default = 30
        subject.gitaly_timeout_medium = 50
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_invalid
      end

      it 'rejects medium timeout smaller than fast' do
        subject.gitaly_timeout_default = 30
        subject.gitaly_timeout_medium = 15
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_invalid
      end

      it 'does not prevent from saving when gitaly timeouts were previously invalid' do
        subject.update_column(:gitaly_timeout_default, Settings.gitlab.max_request_duration_seconds + 1)

        expect(subject.reload).to be_valid
      end
    end

    describe 'enforcing terms' do
      it 'requires the terms to present when enforcing users to accept' do
        subject.enforce_terms = true

        expect(subject).to be_invalid
      end

      it 'is valid when terms are created' do
        create(:term)
        subject.enforce_terms = true

        expect(subject).to be_valid
      end
    end

    describe 'when external authorization service is enabled' do
      before do
        setting.external_authorization_service_enabled = true
      end

      it { is_expected.not_to allow_value('not a URL').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('https://example.com').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('').for(:external_authorization_service_url) }
      it { is_expected.not_to allow_value(nil).for(:external_authorization_service_default_label) }
      it { is_expected.not_to allow_value(11).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value(0).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value('not a certificate').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_key) }

      context 'when setting a valid client certificate for external authorization' do
        let(:certificate_data) { File.read('spec/fixtures/passphrase_x509_certificate.crt') }

        before do
          setting.external_auth_client_cert = certificate_data
        end

        it 'requires a valid client key when a certificate is set' do
          expect(setting).not_to allow_value('fefefe').for(:external_auth_client_key)
        end

        it 'requires a matching certificate' do
          other_private_key = File.read('spec/fixtures/x509_certificate_pk.key')

          expect(setting).not_to allow_value(other_private_key).for(:external_auth_client_key)
        end

        it 'the credentials are valid when the private key can be read and matches the certificate' do
          tls_attributes = [:external_auth_client_key_pass,
            :external_auth_client_key,
            :external_auth_client_cert]
          setting.external_auth_client_key = File.read('spec/fixtures/passphrase_x509_certificate_pk.key')
          setting.external_auth_client_key_pass = '5iveL!fe'

          setting.validate

          expect(setting.errors).not_to include(*tls_attributes)
        end
      end
    end

    context 'with asset proxy settings' do
      before do
        subject.asset_proxy_enabled = true
      end

      describe '#asset_proxy_url' do
        it { is_expected.not_to allow_value('').for(:asset_proxy_url) }
        it { is_expected.to allow_value(http).for(:asset_proxy_url) }
        it { is_expected.to allow_value(https).for(:asset_proxy_url) }
        it { is_expected.not_to allow_value(ftp).for(:asset_proxy_url) }

        it 'is not required when asset proxy is disabled' do
          subject.asset_proxy_enabled = false
          subject.asset_proxy_url = ''

          expect(subject).to be_valid
        end
      end

      describe '#asset_proxy_secret_key' do
        it { is_expected.not_to allow_value('').for(:asset_proxy_secret_key) }
        it { is_expected.to allow_value('anything').for(:asset_proxy_secret_key) }

        it 'is not required when asset proxy is disabled' do
          subject.asset_proxy_enabled = false
          subject.asset_proxy_secret_key = ''

          expect(subject).to be_valid
        end

        it 'is encrypted' do
          subject.asset_proxy_secret_key = 'shared secret'

          expect(subject.encrypted_asset_proxy_secret_key).to be_present
          expect(subject.encrypted_asset_proxy_secret_key).not_to eq(subject.asset_proxy_secret_key)
        end
      end

      describe '#asset_proxy_whitelist' do
        context 'when given an Array' do
          it 'sets the domains and adds current running host' do
            setting.asset_proxy_whitelist = ['example.com', 'assets.example.com']
            expect(setting.asset_proxy_whitelist).to eq(['example.com', 'assets.example.com', 'localhost'])
          end
        end

        context 'when given a String' do
          it 'sets multiple domains with spaces' do
            setting.asset_proxy_whitelist = 'example.com *.example.com'
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with newlines and a space' do
            setting.asset_proxy_whitelist = "example.com\n *.example.com"
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with commas' do
            setting.asset_proxy_whitelist = "example.com, *.example.com"
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end
        end
      end

      describe '#asset_proxy_allowlist' do
        context 'when given an Array' do
          it 'sets the domains and adds current running host' do
            setting.asset_proxy_allowlist = ['example.com', 'assets.example.com']
            expect(setting.asset_proxy_allowlist).to eq(['example.com', 'assets.example.com', 'localhost'])
          end
        end

        context 'when given a String' do
          it 'sets multiple domains with spaces' do
            setting.asset_proxy_allowlist = 'example.com *.example.com'
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with newlines and a space' do
            setting.asset_proxy_allowlist = "example.com\n *.example.com"
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with commas' do
            setting.asset_proxy_allowlist = "example.com, *.example.com"
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end
        end
      end

      describe '#ci_jwt_signing_key' do
        it { is_expected.not_to allow_value('').for(:ci_jwt_signing_key) }
        it { is_expected.not_to allow_value('invalid RSA key').for(:ci_jwt_signing_key) }
        it { is_expected.to allow_value(nil).for(:ci_jwt_signing_key) }
        it { is_expected.to allow_value(OpenSSL::PKey::RSA.new(1024).to_pem).for(:ci_jwt_signing_key) }

        it 'is encrypted' do
          subject.ci_jwt_signing_key = OpenSSL::PKey::RSA.new(1024).to_pem

          aggregate_failures do
            expect(subject.encrypted_ci_jwt_signing_key).to be_present
            expect(subject.encrypted_ci_jwt_signing_key_iv).to be_present
            expect(subject.encrypted_ci_jwt_signing_key).not_to eq(subject.ci_jwt_signing_key)
          end
        end
      end

      describe '#ci_job_token_signing_key', :do_not_stub_ci_job_token_signing_key do
        it { is_expected.not_to allow_value('').for(:ci_job_token_signing_key) }
        it { is_expected.not_to allow_value('invalid RSA key').for(:ci_job_token_signing_key) }
        it { is_expected.to allow_value(nil).for(:ci_job_token_signing_key) }
        it { is_expected.to allow_value(OpenSSL::PKey::RSA.new(1024).to_pem).for(:ci_job_token_signing_key) }

        it 'is encrypted' do
          subject.ci_job_token_signing_key = OpenSSL::PKey::RSA.new(1024).to_pem

          aggregate_failures do
            expect(subject.encrypted_ci_job_token_signing_key).to be_present
            expect(subject.encrypted_ci_job_token_signing_key_iv).to be_present
            expect(subject.encrypted_ci_job_token_signing_key).not_to eq(subject.ci_job_token_signing_key)
          end
        end
      end

      describe '#customers_dot_jwt_signing_key' do
        it { is_expected.not_to allow_value('').for(:customers_dot_jwt_signing_key) }
        it { is_expected.not_to allow_value('invalid RSA key').for(:customers_dot_jwt_signing_key) }
        it { is_expected.to allow_value(nil).for(:customers_dot_jwt_signing_key) }
        it { is_expected.to allow_value(OpenSSL::PKey::RSA.new(1024).to_pem).for(:customers_dot_jwt_signing_key) }

        it 'is encrypted' do
          subject.customers_dot_jwt_signing_key = OpenSSL::PKey::RSA.new(1024).to_pem

          aggregate_failures do
            expect(subject.encrypted_customers_dot_jwt_signing_key).to be_present
            expect(subject.encrypted_customers_dot_jwt_signing_key_iv).to be_present
            expect(subject.encrypted_customers_dot_jwt_signing_key).not_to eq(subject.customers_dot_jwt_signing_key)
          end
        end
      end

      describe '#cloud_license_auth_token' do
        it { is_expected.to allow_value(nil).for(:cloud_license_auth_token) }

        it 'is encrypted' do
          subject.cloud_license_auth_token = 'token-from-customers-dot'

          aggregate_failures do
            expect(subject.encrypted_cloud_license_auth_token).to be_present
            expect(subject.encrypted_cloud_license_auth_token_iv).to be_present
            expect(subject.encrypted_cloud_license_auth_token).not_to eq(subject.cloud_license_auth_token)
          end
        end
      end
    end

    context 'for static objects external storage' do
      context 'when URL is set' do
        before do
          subject.static_objects_external_storage_url = http
        end

        it { is_expected.not_to allow_value(nil).for(:static_objects_external_storage_auth_token) }
      end
    end

    context 'with sourcegraph settings' do
      it 'is invalid if sourcegraph is enabled and no url is provided' do
        allow(subject).to receive(:sourcegraph_enabled).and_return(true)

        expect(subject.sourcegraph_url).to be_nil
        is_expected.to be_invalid
      end
    end

    context 'with gitpod settings' do
      it 'is invalid if gitpod is enabled and no url is provided' do
        allow(subject).to receive_messages(gitpod_enabled: true, gitpod_url: nil)

        is_expected.to be_invalid
      end

      it 'is invalid if gitpod is enabled and an empty url is provided' do
        allow(subject).to receive_messages(gitpod_enabled: true, gitpod_url: '')

        is_expected.to be_invalid
      end

      it 'is invalid if gitpod is enabled and an invalid url is provided' do
        allow(subject).to receive_messages(gitpod_enabled: true, gitpod_url: 'javascript:alert("test")//')

        is_expected.to be_invalid
      end
    end

    describe 'diagrams.net settings' do
      context 'when diagrams.net is enabled' do
        before do
          setting.diagramsnet_enabled = true
        end

        it { is_expected.not_to allow_value(nil).for(:diagramsnet_url) }
        it { is_expected.to allow_value("https://embed.diagrams.net").for(:diagramsnet_url) }
        it { is_expected.not_to allow_value('not a URL').for(:diagramsnet_url) }
      end

      context 'when diagrams.net is not enabled' do
        before do
          setting.diagramsnet_enabled = false
        end

        it { is_expected.to allow_value(nil).for(:diagramsnet_url) }
      end
    end

    context 'with sidekiq job limiter settings' do
      it 'has the right defaults', :aggregate_failures do
        expect(setting.sidekiq_job_limiter_mode).to eq('compress')
        expect(setting.sidekiq_job_limiter_compression_threshold_bytes)
          .to eq(Gitlab::SidekiqMiddleware::SizeLimiter::Validator::DEFAULT_COMPRESSION_THRESHOLD_BYTES)
        expect(setting.sidekiq_job_limiter_limit_bytes)
          .to eq(Gitlab::SidekiqMiddleware::SizeLimiter::Validator::DEFAULT_SIZE_LIMIT)
      end

      it { is_expected.to allow_value('track').for(:sidekiq_job_limiter_mode) }
    end

    context 'with prometheus settings' do
      it 'validates metrics_method_call_threshold' do
        allow(subject).to receive(:prometheus_metrics_enabled).and_return(true)

        is_expected.to validate_numericality_of(:metrics_method_call_threshold).is_greater_than_or_equal_to(0)
      end
    end

    context 'with error tracking settings' do
      context 'with error tracking disabled' do
        before do
          setting.error_tracking_enabled = false
        end

        it { is_expected.to allow_value(nil).for(:error_tracking_api_url) }
      end

      context 'with error tracking enabled' do
        before do
          setting.error_tracking_enabled = true
        end

        it { is_expected.to allow_value(http).for(:error_tracking_api_url) }
        it { is_expected.to allow_value(https).for(:error_tracking_api_url) }
        it { is_expected.not_to allow_value(ftp).for(:error_tracking_api_url) }
        it { is_expected.to validate_presence_of(:error_tracking_api_url) }
      end
    end

    context 'for default_preferred_language' do
      it { is_expected.to allow_value(*Gitlab::I18n.available_locales).for(:default_preferred_language) }
      it { is_expected.not_to allow_value(nil, '', 'invalid_locale').for(:default_preferred_language) }
    end

    context 'for default_syntax_highlighting_theme' do
      it { is_expected.to allow_value(*Gitlab::ColorSchemes.valid_ids).for(:default_syntax_highlighting_theme) }

      it do
        is_expected.not_to allow_value(nil, 0,
          Gitlab::ColorSchemes.available_schemes.size + 1).for(:default_syntax_highlighting_theme)
      end
    end

    context 'for default_branch_protections_defaults validations' do
      let(:charset) { [*'a'..'z'] + [*0..9] }
      let(:value) { Array.new(byte_size) { charset.sample }.join }

      it { expect(described_class).to validate_jsonb_schema(['default_branch_protection_defaults']) }

      context 'when json is more than 1kb' do
        let(:byte_size) { 1.1.kilobytes }

        it { is_expected.not_to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end

      context 'when json less than 1kb' do
        let(:byte_size) { 0.5.kilobytes }

        it { is_expected.to allow_value({ name: value }).for(:default_branch_protection_defaults) }
      end
    end

    context 'for default_project_visibility, default_group_visibility and restricted_visibility_levels validations' do
      before do
        subject.restricted_visibility_levels = [10]
      end

      it { is_expected.not_to allow_value(10).for(:default_group_visibility) }
      it { is_expected.not_to allow_value(10).for(:default_project_visibility) }
      it { is_expected.to allow_value(20).for(:default_group_visibility) }
      it { is_expected.to allow_value(20).for(:default_project_visibility) }

      it 'sets error messages when default visibility settings are not valid' do
        subject.default_group_visibility = 10
        subject.default_project_visibility = 10

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:default_group_visibility].first)
          .to eq("cannot be set to a restricted visibility level")
        expect(subject.errors.messages[:default_project_visibility].first)
          .to eq("cannot be set to a restricted visibility level")
      end
    end

    describe 'sentry_clientside_traces_sample_rate' do
      it do
        is_expected.to validate_numericality_of(:sentry_clientside_traces_sample_rate)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(1)
          .with_message("must be a value between 0 and 1")
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :ensure_runners_registration_token' do
      it 'populates #runners_registration_token before save' do
        application_setting = build(:application_setting)

        # Don't use reader method as it lazily populates the token.
        # See the tests for #runners_registration_token below.
        expect(application_setting.attributes['runners_registration_token_encrypted']).to be_nil

        application_setting.save!

        expect(application_setting.attributes['runners_registration_token_encrypted']).to be_present
      end
    end

    describe 'before_save :ensure_health_check_access_token' do
      it 'populates #runners_registration_token before save' do
        application_setting = build(:application_setting)

        # Don't use reader method as it lazily populates the token.
        # See the tests for #health_check_access_token below.
        expect(application_setting.attributes['health_check_access_token']).to be_nil

        application_setting.save!

        expect(application_setting.attributes['health_check_access_token']).to be_present
      end
    end

    describe 'before_save :ensure_error_tracking_access_token' do
      it 'populates #runners_registration_token before save' do
        application_setting = build(:application_setting)

        # Don't use reader method as it lazily populates the token.
        # See the tests for #error_tracking_access_token below.
        expect(application_setting.attributes['error_tracking_access_token_encrypted']).to be_nil

        application_setting.save!

        expect(application_setting.attributes['error_tracking_access_token_encrypted']).to be_present
      end
    end
  end

  describe '#runners_registration_token' do
    context 'when allowed by application setting' do
      before do
        stub_application_setting(allow_runner_registration_token: true)
      end

      it 'is lazily populated and persists the record' do
        application_setting = build(:application_setting)

        expect(application_setting.runners_registration_token).to be_present
        expect(application_setting).to be_persisted
      end
    end

    context 'when disallowed by application setting' do
      before do
        stub_application_setting(allow_runner_registration_token: false)
      end

      it 'is not lazily populated' do
        expect(build(:application_setting).runners_registration_token).to be_nil
      end
    end
  end

  describe '#health_check_access_token' do
    it 'is lazily populated and persists the record' do
      application_setting = build(:application_setting)

      expect(application_setting.health_check_access_token).to be_present
      expect(application_setting).to be_persisted
    end
  end

  describe '#error_tracking_access_token' do
    it 'is lazily populated and persists the record' do
      application_setting = build(:application_setting)

      expect(application_setting.error_tracking_access_token).to be_present
      expect(application_setting).to be_persisted
    end
  end

  context 'when restrict creating duplicates' do
    let!(:current_settings) { described_class.create_from_defaults }

    it 'returns the current settings' do
      expect(described_class.create_from_defaults).to eq(current_settings)
    end
  end

  context 'when ApplicationSettings does not have a primary key' do
    before do
      allow(described_class.connection).to receive(:primary_key).with(described_class.table_name).and_return(nil)
    end

    it 'raises an exception' do
      expect { described_class.create_from_defaults }.to raise_error(/table is missing a primary key constraint/)
    end
  end

  describe 'ADDRESSABLE_URL_VALIDATION_OPTIONS' do
    it 'is applied to all addressable_url validated properties' do
      url_validators = described_class.validators.select { |validator| validator.is_a?(AddressableUrlValidator) }

      url_validators.each do |validator|
        expect(validator.options).to match(hash_including(described_class::ADDRESSABLE_URL_VALIDATION_OPTIONS)),
          "#{validator.attributes} should use ADDRESSABLE_URL_VALIDATION_OPTIONS"
      end
    end
  end

  describe '#disabled_oauth_sign_in_sources=' do
    before do
      allow(Devise).to receive(:omniauth_providers).and_return([:github])
    end

    it 'removes unknown sources (as strings) from the array' do
      subject.disabled_oauth_sign_in_sources = %w[github test]

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to eq ['github']
    end

    it 'removes unknown sources (as symbols) from the array' do
      subject.disabled_oauth_sign_in_sources = %i[github test]

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to eq ['github']
    end

    it 'ignores nil' do
      subject.disabled_oauth_sign_in_sources = nil

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to be_empty
    end
  end

  describe 'performance bar settings' do
    describe 'performance_bar_allowed_group' do
      context 'with no performance_bar_allowed_group_id saved' do
        it 'returns nil' do
          expect(setting.performance_bar_allowed_group).to be_nil
        end
      end

      context 'with a performance_bar_allowed_group_id saved' do
        let(:group) { create(:group) }

        before do
          setting.update!(performance_bar_allowed_group_id: group.id)
        end

        it 'returns the group' do
          expect(setting.reload.performance_bar_allowed_group).to eq(group)
        end
      end
    end

    describe 'performance_bar_enabled' do
      context 'with the Performance Bar is enabled' do
        let(:group) { create(:group) }

        before do
          setting.update!(performance_bar_allowed_group_id: group.id)
        end

        it 'returns true' do
          expect(setting.reload.performance_bar_enabled).to be_truthy
        end
      end
    end
  end

  context 'with diff limit settings' do
    describe '#diff_max_patch_bytes' do
      context 'for validations' do
        it { is_expected.to validate_presence_of(:diff_max_patch_bytes) }

        it do
          is_expected.to validate_numericality_of(:diff_max_patch_bytes)
          .only_integer
          .is_greater_than_or_equal_to(Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES)
          .is_less_than_or_equal_to(Gitlab::Git::Diff::MAX_PATCH_BYTES_UPPER_BOUND)
        end
      end
    end

    describe '#diff_max_files' do
      context 'for validations' do
        it { is_expected.to validate_presence_of(:diff_max_files) }

        it do
          is_expected
            .to validate_numericality_of(:diff_max_files)
            .only_integer
            .is_greater_than_or_equal_to(Commit::DEFAULT_MAX_DIFF_FILES_SETTING)
            .is_less_than_or_equal_to(Commit::MAX_DIFF_FILES_SETTING_UPPER_BOUND)
        end
      end
    end

    describe '#diff_max_lines' do
      context 'for validations' do
        it { is_expected.to validate_presence_of(:diff_max_lines) }

        it do
          is_expected
            .to validate_numericality_of(:diff_max_lines)
            .only_integer
            .is_greater_than_or_equal_to(Commit::DEFAULT_MAX_DIFF_LINES_SETTING)
            .is_less_than_or_equal_to(Commit::MAX_DIFF_LINES_SETTING_UPPER_BOUND)
        end
      end
    end
  end

  describe '#sourcegraph_url_is_com?' do
    where(:url, :is_com) do
      'https://sourcegraph.com' | true
      'https://sourcegraph.com/' | true
      'https://www.sourcegraph.com' | true
      'shttps://www.sourcegraph.com' | false
      'https://sourcegraph.example.com/' | false
      'https://sourcegraph.org/' | false
    end

    with_them do
      it 'matches the url with sourcegraph.com' do
        setting.sourcegraph_url = url

        expect(setting.sourcegraph_url_is_com?).to eq(is_com)
      end
    end
  end

  describe '#instance_review_permitted?', :request_store, :use_clean_rails_memory_store_caching, :without_license do
    subject { setting.instance_review_permitted? }

    before do
      allow(Rails.cache).to receive(:fetch).and_call_original
    end

    where(users_over_minimum: [-1, 0, 1])

    with_them do
      it do
        expect(Rails.cache).to receive(:fetch).with('limited_users_count', anything)
          .and_return(::ApplicationSetting::INSTANCE_REVIEW_MIN_USERS + users_over_minimum)
        is_expected.to be(users_over_minimum >= 0)
      end
    end
  end

  describe 'email_restrictions' do
    context 'when email restrictions are enabled' do
      before do
        subject.email_restrictions_enabled = true
      end

      it 'allows empty email restrictions' do
        subject.email_restrictions = ''

        expect(subject).to be_valid
      end

      it 'accepts valid email restrictions regex' do
        subject.email_restrictions = '\+'

        expect(subject).to be_valid
      end

      it 'does not accept invalid email restrictions regex' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
      end

      it 'sets an error when regex is not valid' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:email_restrictions].first)
          .to eq(_('not valid RE2 syntax: no argument for repetition operator: +'))
      end
    end

    context 'when email restrictions are disabled' do
      before do
        subject.email_restrictions_enabled = false
      end

      it 'allows empty email restrictions' do
        subject.email_restrictions = ''

        expect(subject).to be_valid
      end

      it 'invalid regex is not valid' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
      end
    end
  end

  it_behaves_like 'application settings examples'

  describe 'kroki_format_supported?' do
    it 'returns true when Excalidraw is enabled' do
      subject.kroki_formats_excalidraw = true
      expect(subject.kroki_format_supported?('excalidraw')).to be(true)
    end

    it 'returns true when BlockDiag is enabled' do
      subject.kroki_formats_blockdiag = true
      # format "blockdiag" aggregates multiple diagram types: actdiag, blockdiag, nwdiag...
      expect(subject.kroki_format_supported?('actdiag')).to be(true)
      expect(subject.kroki_format_supported?('blockdiag')).to be(true)
    end

    it 'returns false when BlockDiag is disabled' do
      subject.kroki_formats_blockdiag = false
      # format "blockdiag" aggregates multiple diagram types: actdiag, blockdiag, nwdiag...
      expect(subject.kroki_format_supported?('actdiag')).to be(false)
      expect(subject.kroki_format_supported?('blockdiag')).to be(false)
    end

    it 'returns false when the diagram type is optional and not enabled' do
      expect(subject.kroki_format_supported?('bpmn')).to be(false)
    end

    it 'returns true when the diagram type is enabled by default' do
      expect(subject.kroki_format_supported?('vegalite')).to be(true)
      expect(subject.kroki_format_supported?('nomnoml')).to be(true)
      expect(subject.kroki_format_supported?('unknown-diagram-type')).to be(false)
    end

    it 'returns false when the diagram type is unknown' do
      expect(subject.kroki_format_supported?('unknown-diagram-type')).to be(false)
    end
  end

  describe 'kroki_formats' do
    it 'returns the value for kroki_formats' do
      subject.kroki_formats = { blockdiag: true, bpmn: false, excalidraw: true }
      expect(subject.kroki_formats_blockdiag).to be(true)
      expect(subject.kroki_formats_bpmn).to be(false)
      expect(subject.kroki_formats_excalidraw).to be(true)
    end
  end

  describe 'default_branch_protection_defaults' do
    let(:defaults) { { name: 'main', push_access_level: 30, merge_access_level: 30, unprotect_access_level: 40 } }

    it 'returns the value for default_branch_protection_defaults' do
      subject.default_branch_protection_defaults = defaults
      expect(subject.default_branch_protection_defaults['name']).to eq('main')
      expect(subject.default_branch_protection_defaults['push_access_level']).to eq(30)
      expect(subject.default_branch_protection_defaults['merge_access_level']).to eq(30)
      expect(subject.default_branch_protection_defaults['unprotect_access_level']).to eq(40)
    end

    context 'when provided with content that does not match the JSON schema' do
      # valid json
      it { is_expected.to allow_value({ name: 'bar' }).for(:default_branch_protection_defaults) }

      # invalid json
      it { is_expected.not_to allow_value({ foo: 'bar' }).for(:default_branch_protection_defaults) }
    end
  end

  describe '#static_objects_external_storage_auth_token=', :aggregate_failures do
    subject { setting.static_objects_external_storage_auth_token = token }

    let(:token) { 'Test' }

    it 'stores an encrypted version of the token' do
      subject

      expect(setting[:static_objects_external_storage_auth_token]).to be_nil
      expect(setting[:static_objects_external_storage_auth_token_encrypted]).to be_present
      expect(setting.static_objects_external_storage_auth_token).to eq('Test')
    end

    context 'when token is empty' do
      let(:token) { '' }

      it 'removes an encrypted version of the token' do
        subject

        expect(setting[:static_objects_external_storage_auth_token]).to be_nil
        expect(setting[:static_objects_external_storage_auth_token_encrypted]).to be_nil
        expect(setting.static_objects_external_storage_auth_token).to be_nil
      end
    end

    context 'with plaintext token only' do
      let(:plaintext_token) { Devise.friendly_token(20) }

      it 'encrypts the plaintext token' do
        subject

        described_class.update!(static_objects_external_storage_auth_token: plaintext_token)

        setting.reload
        expect(setting[:static_objects_external_storage_auth_token]).to be_nil
        expect(setting[:static_objects_external_storage_auth_token_encrypted]).not_to be_nil
        expect(setting.static_objects_external_storage_auth_token).to eq(plaintext_token)
      end
    end
  end

  describe '#database_grafana_api_key' do
    it 'is encrypted' do
      subject.database_grafana_api_key = 'somesecret'

      aggregate_failures do
        expect(subject.encrypted_database_grafana_api_key).to be_present
        expect(subject.encrypted_database_grafana_api_key_iv).to be_present
        expect(subject.encrypted_database_grafana_api_key).not_to eq(subject.database_grafana_api_key)
      end
    end
  end

  context "when inactive project deletion" do
    it "validates warning email after months is less than delete after months" do
      subject[:inactive_projects_delete_after_months] = 3
      subject[:inactive_projects_send_warning_email_after_months] = 6

      expect(subject).to be_invalid
    end

    it do
      is_expected.to validate_numericality_of(:inactive_projects_send_warning_email_after_months).is_greater_than(0)
    end

    it { is_expected.to validate_numericality_of(:inactive_projects_delete_after_months).is_greater_than(0) }

    it "deletes the redis key used for tracking inactive projects deletion warning emails when setting is updated",
      :clean_gitlab_redis_shared_state do
      Gitlab::Redis::SharedState.with do |redis|
        redis.hset("inactive_projects_deletion_warning_email_notified", "project:1", "2020-01-01")
      end

      Gitlab::Redis::SharedState.with do |redis|
        expect { setting.update!(inactive_projects_delete_after_months: 6) }
          .to change { redis.hgetall('inactive_projects_deletion_warning_email_notified') }.to({})
      end
    end
  end

  context 'with personal accesss token prefix' do
    it 'sets the correct default value' do
      expect(setting.personal_access_token_prefix).to eql('glpat-')
    end
  end

  describe '.personal_access_tokens_disabled?' do
    it 'is false' do
      expect(setting.personal_access_tokens_disabled?).to be(false)
    end
  end

  context 'for security txt content' do
    it { is_expected.to validate_length_of(:security_txt_content).is_at_most(2048) }
  end

  context 'for ascii max includes' do
    it { is_expected.to validate_numericality_of(:asciidoc_max_includes).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:asciidoc_max_includes).only_integer.is_less_than_or_equal_to(64) }
  end

  describe 'after_commit callback' do
    before do
      allow(setting).to receive(:reset_deletion_warning_redis_key)
    end

    context 'when inactive_projects_delete_after_months changes' do
      it 'calls reset_deletion_warning_redis_key' do
        setting.update!(inactive_projects_delete_after_months: 6)
        expect(setting).to have_received(:reset_deletion_warning_redis_key)
      end
    end

    context 'when delete_inactive_projects changes from true to false' do
      it 'calls reset_deletion_warning_redis_key' do
        setting.update!(delete_inactive_projects: true)
        setting.update!(delete_inactive_projects: false)
        expect(setting).to have_received(:reset_deletion_warning_redis_key)
      end
    end

    context 'when delete_inactive_projects changes from false to true' do
      it 'does not call reset_deletion_warning_redis_key' do
        setting.update!(delete_inactive_projects: true)
        expect(setting).not_to have_received(:reset_deletion_warning_redis_key)
      end
    end

    context 'when there are no relevant changes' do
      it 'does not call reset_deletion_warning_redis_key' do
        setting.update!(default_artifacts_expire_in: 30)
        expect(setting).not_to have_received(:reset_deletion_warning_redis_key)
      end
    end
  end

  it_behaves_like 'TokenAuthenticatable' do
    let(:token_field) { :runners_registration_token }
  end
end
