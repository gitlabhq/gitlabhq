# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Settings, 'Settings', :do_not_mock_admin_mode_setting, feature_category: :shared do
  let(:user) { create(:user) }

  let_it_be(:admin) { create(:admin) }

  describe "GET /application/settings" do
    before do
      # Testing config file config/gitlab.yml becomes SSOT for this API
      # see https://gitlab.com/gitlab-org/gitlab/-/issues/426091#note_1675160909
      stub_storage_settings({ 'default' => {}, 'custom' => {} })
    end

    it "returns application settings" do
      get api("/application/settings", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['password_authentication_enabled_for_web']).to be_truthy
      expect(json_response['repository_storages_weighted']).to eq({ 'default' => 100, 'custom' => 0 })
      expect(json_response['password_authentication_enabled']).to be_truthy
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
      expect(json_response['diagramsnet_enabled']).to be_truthy
      expect(json_response['diagramsnet_url']).to eq('https://embed.diagrams.net')
      expect(json_response['default_ci_config_path']).to be_nil
      expect(json_response['sourcegraph_enabled']).to be_falsey
      expect(json_response['sourcegraph_url']).to be_nil
      expect(json_response['secret_detection_token_revocation_url']).to be_nil
      expect(json_response['secret_detection_revocation_token_types_url']).to be_nil
      expect(json_response['sourcegraph_public_only']).to be_truthy
      expect(json_response['decompress_archive_file_timeout']).to eq(210)
      expect(json_response['default_preferred_language']).to be_a String
      expect(json_response['default_project_visibility']).to be_a String
      expect(json_response['default_snippet_visibility']).to be_a String
      expect(json_response['default_group_visibility']).to be_a String
      expect(json_response['rsa_key_restriction']).to eq(0)
      expect(json_response['dsa_key_restriction']).to eq(0)
      expect(json_response['ecdsa_key_restriction']).to eq(0)
      expect(json_response['ed25519_key_restriction']).to eq(0)
      expect(json_response['ecdsa_sk_key_restriction']).to eq(0)
      expect(json_response['ed25519_sk_key_restriction']).to eq(0)
      expect(json_response['performance_bar_allowed_group_id']).to be_nil
      expect(json_response['allow_local_requests_from_hooks_and_services']).to be(false)
      expect(json_response['allow_local_requests_from_web_hooks_and_services']).to be(false)
      expect(json_response['allow_local_requests_from_system_hooks']).to be(true)
      expect(json_response).not_to have_key('performance_bar_allowed_group_path')
      expect(json_response).not_to have_key('performance_bar_enabled')
      expect(json_response['snippet_size_limit']).to eq(50.megabytes)
      expect(json_response['spam_check_endpoint_enabled']).to be_falsey
      expect(json_response['spam_check_endpoint_url']).to be_nil
      expect(json_response['spam_check_api_key']).to be_nil
      expect(json_response['wiki_page_max_content_bytes']).to be_a(Integer)
      expect(json_response['wiki_asciidoc_allow_uri_includes']).to be_falsey
      expect(json_response['require_admin_approval_after_user_signup']).to eq(true)
      expect(json_response['personal_access_token_prefix']).to eq('glpat-')
      expect(json_response['admin_mode']).to be(false)
      expect(json_response['whats_new_variant']).to eq('all_tiers')
      expect(json_response['user_deactivation_emails_enabled']).to be(true)
      expect(json_response['suggest_pipeline_enabled']).to be(true)
      expect(json_response['runner_token_expiration_interval']).to be_nil
      expect(json_response['group_runner_token_expiration_interval']).to be_nil
      expect(json_response['project_runner_token_expiration_interval']).to be_nil
      expect(json_response['max_export_size']).to eq(0)
      expect(json_response['max_decompressed_archive_size']).to eq(25600)
      expect(json_response['max_terraform_state_size_bytes']).to eq(0)
      expect(json_response['pipeline_limit_per_project_user_sha']).to eq(0)
      expect(json_response['delete_inactive_projects']).to be(false)
      expect(json_response['inactive_projects_delete_after_months']).to eq(2)
      expect(json_response['inactive_projects_min_size_mb']).to eq(0)
      expect(json_response['inactive_projects_send_warning_email_after_months']).to eq(1)
      expect(json_response['can_create_group']).to eq(true)
      expect(json_response['jira_connect_application_key']).to eq(nil)
      expect(json_response['jira_connect_public_key_storage_enabled']).to eq(false)
      expect(json_response['jira_connect_proxy_url']).to eq(nil)
      expect(json_response['user_defaults_to_private_profile']).to eq(false)
      expect(json_response['default_syntax_highlighting_theme']).to eq(1)
      expect(json_response['projects_api_rate_limit_unauthenticated']).to eq(400)
      expect(json_response['silent_mode_enabled']).to be(false)
      expect(json_response['slack_app_enabled']).to be(false)
      expect(json_response['slack_app_id']).to be_nil
      expect(json_response['slack_app_secret']).to be_nil
      expect(json_response['slack_app_signing_secret']).to be_nil
      expect(json_response['slack_app_verification_token']).to be_nil
      expect(json_response['valid_runner_registrars']).to match_array(%w[project group])
      expect(json_response['ci_max_includes']).to eq(150)
      expect(json_response['allow_account_deletion']).to eq(true)
      expect(json_response['gitlab_shell_operation_limit']).to eq(600)
      expect(json_response['namespace_aggregation_schedule_lease_duration_in_seconds']).to eq(300)
      expect(json_response['default_branch_protection_defaults']).to be_kind_of(Hash)
      expect(json_response['max_login_attempts']).to be_nil
      expect(json_response['failed_login_attempts_unlock_period_in_minutes']).to be_nil
      expect(json_response['bulk_import_concurrent_pipeline_batch_limit']).to eq(25)
      expect(json_response['downstream_pipeline_trigger_limit_per_project_user_sha']).to eq(0)
      expect(json_response['concurrent_github_import_jobs_limit']).to eq(1000)
      expect(json_response['concurrent_bitbucket_import_jobs_limit']).to eq(100)
      expect(json_response['concurrent_bitbucket_server_import_jobs_limit']).to eq(100)
      expect(json_response['require_personal_access_token_expiry']).to eq(true)
    end
  end

  describe "PUT /application/settings" do
    let(:group) { create(:group) }

    context "custom repository storage type set in the config" do
      before do
        # Add a possible storage to the config
        storages = Gitlab.config.repositories.storages
                     .merge({ 'custom' => 'tmp/tests/custom_repositories' })
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
        stub_feature_flags(sourcegraph: true)
      end

      it "coerces repository_storages_weighted to an int" do
        put api("/application/settings", admin),
          params: {
            repository_storages_weighted: { 'custom' => '75' }
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['repository_storages_weighted']).to eq({ 'default' => 0, 'custom' => 75 })
      end

      context "repository_storages_weighted value is outside a 0-100 range" do
        [-1, 101].each do |out_of_range_int|
          it "returns a :bad_request for #{out_of_range_int}" do
            put api("/application/settings", admin),
              params: {
                repository_storages_weighted: { 'custom' => out_of_range_int }
              }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      it "updates application settings", fips_mode: false do
        put api("/application/settings", admin),
          params: {
            default_ci_config_path: 'debian/salsa-ci.yml',
            default_projects_limit: 3,
            default_project_creation: 2,
            password_authentication_enabled_for_web: false,
            repository_storages_weighted: { 'default' => 100, 'custom' => 0 },
            plantuml_enabled: true,
            plantuml_url: 'http://plantuml.example.com',
            diagramsnet_enabled: false,
            diagramsnet_url: nil,
            sourcegraph_enabled: true,
            sourcegraph_url: 'https://sourcegraph.com',
            sourcegraph_public_only: false,
            default_snippet_visibility: 'internal',
            restricted_visibility_levels: 'public',
            default_artifacts_expire_in: '2 days',
            help_page_text: 'custom help text',
            help_page_hide_commercial_content: true,
            help_page_support_url: 'http://example.com/help',
            help_page_documentation_base_url: 'https://docs.gitlab.com',
            project_export_enabled: false,
            rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE,
            dsa_key_restriction: 2048,
            ecdsa_key_restriction: 384,
            ed25519_key_restriction: 256,
            ecdsa_sk_key_restriction: 256,
            ed25519_sk_key_restriction: 256,
            enforce_terms: true,
            terms: 'Hello world!',
            performance_bar_allowed_group_path: group.full_path,
            decompress_archive_file_timeout: 60,
            diff_max_patch_bytes: 300_000,
            diff_max_files: 2000,
            diff_max_lines: 50000,
            default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE,
            default_branch_protection_defaults: ::Gitlab::Access::BranchProtection.protected_after_initial_push.stringify_keys,
            local_markdown_version: 3,
            allow_local_requests_from_web_hooks_and_services: true,
            allow_local_requests_from_system_hooks: false,
            push_event_hooks_limit: 2,
            push_event_activities_limit: 2,
            snippet_size_limit: 5,
            issues_create_limit: 300,
            raw_blob_request_limit: 300,
            spam_check_endpoint_enabled: true,
            spam_check_endpoint_url: 'grpc://example.com/spam_check',
            spam_check_api_key: 'SPAM_CHECK_API_KEY',
            mailgun_events_enabled: true,
            mailgun_signing_key: 'MAILGUN_SIGNING_KEY',
            max_export_size: 6,
            max_decompressed_archive_size: 20000,
            max_terraform_state_size_bytes: 1_000,
            disabled_oauth_sign_in_sources: 'unknown',
            import_sources: 'github,bitbucket',
            wiki_page_max_content_bytes: 12345,
            wiki_asciidoc_allow_uri_includes: true,
            personal_access_token_prefix: "GL-",
            user_deactivation_emails_enabled: false,
            admin_mode: true,
            suggest_pipeline_enabled: false,
            users_get_by_id_limit: 456,
            delete_inactive_projects: true,
            inactive_projects_delete_after_months: 24,
            inactive_projects_min_size_mb: 10,
            inactive_projects_send_warning_email_after_months: 12,
            can_create_group: false,
            jira_connect_application_key: '123',
            jira_connect_public_key_storage_enabled: true,
            jira_connect_proxy_url: 'http://example.com',
            bulk_import_enabled: false,
            bulk_import_max_download_file_size: 1,
            bulk_import_concurrent_pipeline_batch_limit: 2,
            allow_runner_registration_token: true,
            user_defaults_to_private_profile: true,
            default_syntax_highlighting_theme: 2,
            projects_api_rate_limit_unauthenticated: 100,
            silent_mode_enabled: true,
            valid_runner_registrars: ['group'],
            allow_account_deletion: false,
            gitlab_shell_operation_limit: 500,
            namespace_aggregation_schedule_lease_duration_in_seconds: 400,
            max_import_remote_file_size: 2,
            security_txt_content: nil,
            downstream_pipeline_trigger_limit_per_project_user_sha: 300,
            concurrent_github_import_jobs_limit: 2,
            concurrent_bitbucket_import_jobs_limit: 2,
            concurrent_bitbucket_server_import_jobs_limit: 2,
            require_personal_access_token_expiry: false
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['default_ci_config_path']).to eq('debian/salsa-ci.yml')
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['default_project_creation']).to eq(::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
        expect(json_response['password_authentication_enabled_for_web']).to be_falsey
        expect(json_response['repository_storages_weighted']).to eq({ 'default' => 100, 'custom' => 0 })
        expect(json_response['plantuml_enabled']).to be_truthy
        expect(json_response['plantuml_url']).to eq('http://plantuml.example.com')
        expect(json_response['diagramsnet_enabled']).to be_falsey
        expect(json_response['diagramsnet_url']).to be_nil
        expect(json_response['sourcegraph_enabled']).to be_truthy
        expect(json_response['sourcegraph_url']).to eq('https://sourcegraph.com')
        expect(json_response['sourcegraph_public_only']).to eq(false)
        expect(json_response['default_snippet_visibility']).to eq('internal')
        expect(json_response['restricted_visibility_levels']).to eq(['public'])
        expect(json_response['default_artifacts_expire_in']).to eq('2 days')
        expect(json_response['help_page_text']).to eq('custom help text')
        expect(json_response['help_page_hide_commercial_content']).to be_truthy
        expect(json_response['help_page_support_url']).to eq('http://example.com/help')
        expect(json_response['help_page_documentation_base_url']).to eq('https://docs.gitlab.com')
        expect(json_response['project_export_enabled']).to be_falsey
        expect(json_response['rsa_key_restriction']).to eq(ApplicationSetting::FORBIDDEN_KEY_VALUE)
        expect(json_response['dsa_key_restriction']).to eq(2048)
        expect(json_response['ecdsa_key_restriction']).to eq(384)
        expect(json_response['ed25519_key_restriction']).to eq(256)
        expect(json_response['ecdsa_sk_key_restriction']).to eq(256)
        expect(json_response['ed25519_sk_key_restriction']).to eq(256)
        expect(json_response['enforce_terms']).to be(true)
        expect(json_response['terms']).to eq('Hello world!')
        expect(json_response['performance_bar_allowed_group_id']).to eq(group.id)
        expect(json_response['decompress_archive_file_timeout']).to eq(60)
        expect(json_response['diff_max_patch_bytes']).to eq(300_000)
        expect(json_response['diff_max_files']).to eq(2000)
        expect(json_response['diff_max_lines']).to eq(50000)
        expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
        expect(json_response['default_branch_protection_defaults']).to eq(::Gitlab::Access::BranchProtection.protected_after_initial_push.stringify_keys)
        expect(json_response['local_markdown_version']).to eq(3)
        expect(json_response['allow_local_requests_from_web_hooks_and_services']).to eq(true)
        expect(json_response['allow_local_requests_from_system_hooks']).to eq(false)
        expect(json_response['push_event_hooks_limit']).to eq(2)
        expect(json_response['push_event_activities_limit']).to eq(2)
        expect(json_response['snippet_size_limit']).to eq(5)
        expect(json_response['issues_create_limit']).to eq(300)
        expect(json_response['raw_blob_request_limit']).to eq(300)
        expect(json_response['spam_check_endpoint_enabled']).to be_truthy
        expect(json_response['spam_check_endpoint_url']).to eq('grpc://example.com/spam_check')
        expect(json_response['spam_check_api_key']).to eq('SPAM_CHECK_API_KEY')
        expect(json_response['mailgun_events_enabled']).to be(true)
        expect(json_response['mailgun_signing_key']).to eq('MAILGUN_SIGNING_KEY')
        expect(json_response['max_export_size']).to eq(6)
        expect(json_response['max_decompressed_archive_size']).to eq(20000)
        expect(json_response['max_terraform_state_size_bytes']).to eq(1_000)
        expect(json_response['disabled_oauth_sign_in_sources']).to eq([])
        expect(json_response['import_sources']).to match_array(%w[github bitbucket])
        expect(json_response['wiki_page_max_content_bytes']).to eq(12345)
        expect(json_response['wiki_asciidoc_allow_uri_includes']).to be(true)
        expect(json_response['personal_access_token_prefix']).to eq("GL-")
        expect(json_response['admin_mode']).to be(true)
        expect(json_response['user_deactivation_emails_enabled']).to be(false)
        expect(json_response['suggest_pipeline_enabled']).to be(false)
        expect(json_response['users_get_by_id_limit']).to eq(456)
        expect(json_response['delete_inactive_projects']).to be(true)
        expect(json_response['inactive_projects_delete_after_months']).to eq(24)
        expect(json_response['inactive_projects_min_size_mb']).to eq(10)
        expect(json_response['inactive_projects_send_warning_email_after_months']).to eq(12)
        expect(json_response['can_create_group']).to eq(false)
        expect(json_response['jira_connect_application_key']).to eq('123')
        expect(json_response['jira_connect_public_key_storage_enabled']).to eq(true)
        expect(json_response['jira_connect_proxy_url']).to eq('http://example.com')
        expect(json_response['bulk_import_enabled']).to be(false)
        expect(json_response['allow_runner_registration_token']).to be(true)
        expect(json_response['user_defaults_to_private_profile']).to be(true)
        expect(json_response['default_syntax_highlighting_theme']).to eq(2)
        expect(json_response['projects_api_rate_limit_unauthenticated']).to be(100)
        expect(json_response['silent_mode_enabled']).to be(true)
        expect(json_response['valid_runner_registrars']).to eq(['group'])
        expect(json_response['allow_account_deletion']).to be(false)
        expect(json_response['gitlab_shell_operation_limit']).to be(500)
        expect(json_response['namespace_aggregation_schedule_lease_duration_in_seconds']).to be(400)
        expect(json_response['max_import_remote_file_size']).to be(2)
        expect(json_response['bulk_import_max_download_file_size']).to be(1)
        expect(json_response['security_txt_content']).to be(nil)
        expect(json_response['bulk_import_concurrent_pipeline_batch_limit']).to be(2)
        expect(json_response['downstream_pipeline_trigger_limit_per_project_user_sha']).to be(300)
        expect(json_response['concurrent_github_import_jobs_limit']).to be(2)
        expect(json_response['concurrent_bitbucket_import_jobs_limit']).to be(2)
        expect(json_response['concurrent_bitbucket_server_import_jobs_limit']).to be(2)
        expect(json_response['require_personal_access_token_expiry']).to be(false)
      end
    end

    it "updates default_branch_protection_defaults from the default_branch_protection param" do
      expected_update = ::Gitlab::Access::BranchProtection.protected_against_developer_pushes.stringify_keys

      put api("/application/settings", admin),
        params: { default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
      expect(ApplicationSetting.first.default_branch_protection_defaults).to eq(expected_update)
    end

    context 'when default_branch_protection_defaults is set to No one' do
      it "updates default_branch_protection_defaults" do
        put api("/application/settings", admin),
          params: {
            default_branch_protection_defaults: {
              allowed_to_push: [{ access_level: 0 }],
              allowed_to_merge: [{ access_level: 0 }]
            }
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['default_branch_protection_defaults']).to eq(
          "allowed_to_merge" => [{ "access_level" => 0 }],
          "allowed_to_push" => [{ "access_level" => 0 }]
        )
      end
    end

    it "supports legacy performance_bar_allowed_group_id" do
      put api("/application/settings", admin),
        params: { performance_bar_allowed_group_id: group.full_path }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['performance_bar_allowed_group_id']).to eq(group.id)
    end

    it "supports legacy performance_bar_enabled" do
      put api("/application/settings", admin),
        params: {
          performance_bar_enabled: false,
          performance_bar_allowed_group_id: group.full_path
        }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['performance_bar_allowed_group_id']).to be_nil
    end

    it 'supports legacy allow_local_requests_from_hooks_and_services' do
      put api("/application/settings", admin),
        params: { allow_local_requests_from_hooks_and_services: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['allow_local_requests_from_hooks_and_services']).to eq(true)
    end

    it 'supports legacy asset_proxy_whitelist' do
      put api("/application/settings", admin),
        params: { asset_proxy_whitelist: ['example.com', '*.example.com'] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['asset_proxy_allowlist']).to eq(['example.com', '*.example.com', 'localhost'])
    end

    it 'supports the deprecated `throttle_unauthenticated_*` attributes' do
      put api('/application/settings', admin), params: {
        throttle_unauthenticated_enabled: true,
        throttle_unauthenticated_period_in_seconds: 123,
        throttle_unauthenticated_requests_per_period: 456
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(
        'throttle_unauthenticated_enabled' => true,
        'throttle_unauthenticated_period_in_seconds' => 123,
        'throttle_unauthenticated_requests_per_period' => 456,
        'throttle_unauthenticated_web_enabled' => true,
        'throttle_unauthenticated_web_period_in_seconds' => 123,
        'throttle_unauthenticated_web_requests_per_period' => 456
      )
    end

    it 'prefers the new `throttle_unauthenticated_web_*` attributes' do
      put api('/application/settings', admin), params: {
        throttle_unauthenticated_enabled: false,
        throttle_unauthenticated_period_in_seconds: 0,
        throttle_unauthenticated_requests_per_period: 0,
        throttle_unauthenticated_web_enabled: true,
        throttle_unauthenticated_web_period_in_seconds: 123,
        throttle_unauthenticated_web_requests_per_period: 456
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(
        'throttle_unauthenticated_enabled' => true,
        'throttle_unauthenticated_period_in_seconds' => 123,
        'throttle_unauthenticated_requests_per_period' => 456,
        'throttle_unauthenticated_web_enabled' => true,
        'throttle_unauthenticated_web_period_in_seconds' => 123,
        'throttle_unauthenticated_web_requests_per_period' => 456
      )
    end

    it 'disables ability to switch to legacy storage' do
      put api("/application/settings", admin), params: { hashed_storage_enabled: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['hashed_storage_enabled']).to eq(true)
    end

    context 'SSH key restriction settings', :fips_mode do
      let(:settings) do
        {
          dsa_key_restriction: -1,
          ecdsa_key_restriction: 256,
          ecdsa_sk_key_restriction: 256,
          ed25519_key_restriction: 256,
          ed25519_sk_key_restriction: 256,
          rsa_key_restriction: 3072
        }
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      it 'does not allow DSA keys' do
        put api("/application/settings", admin), params: { dsa_key_restriction: 1024 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not allow short RSA key values' do
        put api("/application/settings", admin), params: { rsa_key_restriction: 2048 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not allow unrestricted key lengths' do
        types = %w[dsa_key_restriction
                   ecdsa_key_restriction
                   ecdsa_sk_key_restriction
                   ed25519_key_restriction
                   ed25519_sk_key_restriction
                   rsa_key_restriction]

        types.each do |type|
          put api("/application/settings", admin), params: { type => 0 }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    context 'external policy classification settings' do
      let(:settings) do
        {
          external_authorization_service_enabled: true,
          external_authorization_service_url: 'https://custom.service/',
          external_authorization_service_default_label: 'default',
          external_authorization_service_timeout: 9.99,
          external_auth_client_cert: File.read('spec/fixtures/passphrase_x509_certificate.crt'),
          external_auth_client_key: File.read('spec/fixtures/passphrase_x509_certificate_pk.key'),
          external_auth_client_key_pass: "5iveL!fe"
        }
      end

      let(:attribute_names) { settings.keys.map(&:to_s) }

      it 'includes the attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(:ok)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    context "snowplow tracking settings", :do_not_stub_snowplow_by_default do
      let(:settings) do
        {
          snowplow_collector_hostname: "snowplow.example.com",
          snowplow_cookie_domain: ".example.com",
          snowplow_enabled: true,
          snowplow_app_id: "app_id"
        }
      end

      let(:attribute_names) { settings.keys.map(&:to_s) }

      it "includes the attributes in the API" do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(:ok)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it "allows updating the settings" do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      context "missing snowplow_collector_hostname value when snowplow_enabled is true" do
        it "returns a blank parameter error message" do
          put api("/application/settings", admin), params: { snowplow_enabled: true }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response["error"]).to eq("snowplow_collector_hostname is missing")
        end

        it "handles validation errors" do
          put api("/application/settings", admin), params: settings.merge({
            snowplow_collector_hostname: nil
          })

          expect(response).to have_gitlab_http_status(:bad_request)
          message = json_response["message"]
          expect(message["snowplow_collector_hostname"]).to include("can't be blank")
        end
      end
    end

    context 'EKS integration settings' do
      let(:attribute_names) { settings.keys.map(&:to_s) }
      let(:sensitive_attributes) { %w[eks_secret_access_key] }
      let(:exposed_attributes) { attribute_names - sensitive_attributes }

      let(:settings) do
        {
          eks_integration_enabled: true,
          eks_account_id: '123456789012',
          eks_access_key_id: 'access-key-id-12',
          eks_secret_access_key: 'secret-access-key'
        }
      end

      it 'includes attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(:ok)
        exposed_attributes.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'does not include sensitive attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(:ok)
        sensitive_attributes.each do |attribute|
          expect(json_response.keys).not_to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      context 'EKS integration is enabled but params are blank' do
        let(:settings) { Hash[eks_integration_enabled: true] }

        it 'does not update the settings' do
          put api("/application/settings", admin), params: settings

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include('eks_account_id is missing')
          expect(json_response['error']).to include('eks_access_key_id is missing')
          expect(json_response['error']).to include('eks_secret_access_key is missing')
        end
      end
    end

    context 'GitLab for Slack app settings' do
      let(:settings) do
        {
          slack_app_enabled: slack_app_enabled,
          slack_app_id: slack_app_id,
          slack_app_secret: slack_app_secret,
          slack_app_signing_secret: slack_app_signing_secret,
          slack_app_verification_token: slack_app_verification_token
        }
      end

      context 'when GitLab for Slack app is enabled' do
        let(:slack_app_enabled) { true }

        context 'when other params are blank' do
          let(:slack_app_id) { nil }
          let(:slack_app_secret) { nil }
          let(:slack_app_signing_secret) { nil }
          let(:slack_app_verification_token) { nil }

          it 'does not update the settings' do
            put api("/application/settings", admin), params: settings

            expect(response).to have_gitlab_http_status(:bad_request)

            expect(json_response['slack_app_enabled']).to be(nil)
            expect(json_response['slack_app_id']).to be(nil)
            expect(json_response['slack_app_secret']).to be(nil)
            expect(json_response['slack_app_signing_secret']).to be(nil)
            expect(json_response['slack_app_verification_token']).to be(nil)

            message = json_response['message']

            expect(message['slack_app_id']).to include("can't be blank")
            expect(message['slack_app_secret']).to include("can't be blank")
            expect(message['slack_app_signing_secret']).to include("can't be blank")
            expect(message['slack_app_verification_token']).to include("can't be blank")
          end
        end

        context 'when other params are present' do
          let(:slack_app_id) { 'ID' }
          let(:slack_app_secret) { 'SECRET' }
          let(:slack_app_signing_secret) { 'SIGNING_SECRET' }
          let(:slack_app_verification_token) { 'VERIFICATION_TOKEN' }

          it 'updates the settings' do
            put api("/application/settings", admin), params: settings

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['slack_app_enabled']).to be(true)
            expect(json_response['slack_app_id']).to eq('ID')
            expect(json_response['slack_app_secret']).to eq('SECRET')
            expect(json_response['slack_app_signing_secret']).to eq('SIGNING_SECRET')
            expect(json_response['slack_app_verification_token']).to eq('VERIFICATION_TOKEN')
          end
        end
      end

      context 'when GitLab for Slack app is not enabled' do
        let(:slack_app_enabled) { false }
        let(:slack_app_id) { nil }
        let(:slack_app_secret) { nil }
        let(:slack_app_signing_secret) { nil }
        let(:slack_app_verification_token) { nil }

        it 'allows blank attributes' do
          put api("/application/settings", admin), params: settings

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['slack_app_enabled']).to be(false)
          expect(json_response['slack_app_id']).to be(nil)
          expect(json_response['slack_app_secret']).to be(nil)
          expect(json_response['slack_app_signing_secret']).to be(nil)
          expect(json_response['slack_app_verification_token']).to be(nil)
        end
      end
    end

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { plantuml_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('plantuml_url is missing')
      end
    end

    context "missing diagramsnet_url value when diagramsnet_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { diagramsnet_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('diagramsnet_url is missing')
      end
    end

    context 'asset_proxy settings' do
      it 'updates application settings' do
        put api('/application/settings', admin),
          params: {
            asset_proxy_enabled: true,
            asset_proxy_url: 'http://assets.example.com',
            asset_proxy_secret_key: 'shared secret',
            asset_proxy_allowlist: ['example.com', '*.example.com']
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['asset_proxy_enabled']).to be(true)
        expect(json_response['asset_proxy_url']).to eq('http://assets.example.com')
        expect(json_response['asset_proxy_secret_key']).to be_nil
        expect(json_response['asset_proxy_allowlist']).to eq(['example.com', '*.example.com', 'localhost'])
      end

      it 'allows a string for asset_proxy_allowlist' do
        put api('/application/settings', admin),
          params: {
            asset_proxy_allowlist: 'example.com, *.example.com'
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['asset_proxy_allowlist']).to eq(['example.com', '*.example.com', 'localhost'])
      end
    end

    context 'domain_denylist settings' do
      it 'rejects domain_denylist_enabled when domain_denylist is empty' do
        put api('/application/settings', admin),
          params: {
            domain_denylist_enabled: true,
            domain_denylist: []
          }

        expect(response).to have_gitlab_http_status(:bad_request)
        message = json_response["message"]
        expect(message["domain_denylist"]).to eq(["Domain denylist cannot be empty if denylist is enabled."])
      end

      it 'allows array for domain_denylist' do
        put api('/application/settings', admin),
          params: {
            domain_denylist_enabled: true,
            domain_denylist: ['domain1.com', 'domain2.com']
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['domain_denylist_enabled']).to be(true)
        expect(json_response['domain_denylist']).to eq(['domain1.com', 'domain2.com'])
      end

      it 'allows a string for domain_denylist' do
        put api('/application/settings', admin),
          params: {
            domain_denylist_enabled: true,
            domain_denylist: 'domain3.com, *.domain4.com'
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['domain_denylist_enabled']).to be(true)
        expect(json_response['domain_denylist']).to eq(['domain3.com', '*.domain4.com'])
      end
    end

    it 'supports legacy admin_notification_email' do
      put api('/application/settings', admin),
        params: { admin_notification_email: 'test@example.com' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['abuse_notification_email']).to eq('test@example.com')
    end

    it 'supports setting require_admin_approval_after_user_signup' do
      put api('/application/settings', admin),
        params: { require_admin_approval_after_user_signup: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['require_admin_approval_after_user_signup']).to eq(true)
    end

    context "missing sourcegraph_url value when sourcegraph_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { sourcegraph_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('sourcegraph_url is missing')
      end
    end

    context "missing spam_check_endpoint_url value when spam_check_endpoint_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { spam_check_endpoint_enabled: true, spam_check_api_key: "SPAM_CHECK_API_KEY" }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('spam_check_endpoint_url is missing')
      end
    end

    context "overly long spam_check_api_key" do
      it "fails to update the settings with too long spam_check_api_key" do
        put api("/application/settings", admin), params: { spam_check_api_key: "0123456789" * 500 }

        expect(response).to have_gitlab_http_status(:bad_request)
        message = json_response["message"]
        expect(message["spam_check_api_key"]).to include(a_string_matching("is too long"))
      end
    end

    context "missing mailgun_signing_key value when mailgun_events_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { mailgun_events_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('mailgun_signing_key is missing')
      end
    end

    context "personal access token prefix settings" do
      context "handles validation errors" do
        it "fails to update the settings with too long prefix" do
          put api("/application/settings", admin), params: { personal_access_token_prefix: "prefix" * 10 }

          expect(response).to have_gitlab_http_status(:bad_request)
          message = json_response["message"]
          expect(message["personal_access_token_prefix"]).to include(a_string_matching("is too long"))
        end

        it "fails to update the settings with invalid characters in the prefix" do
          put api("/application/settings", admin), params: { personal_access_token_prefix: "éñ" }

          expect(response).to have_gitlab_http_status(:bad_request)
          message = json_response["message"]
          expect(message["personal_access_token_prefix"]).to include(a_string_matching("can contain only letters of the Base64 alphabet"))
        end
      end
    end

    context 'whats_new_variant setting' do
      before do
        Gitlab::CurrentSettings.current_application_settings.whats_new_variant_disabled!
      end

      it 'updates setting' do
        new_value = 'all_tiers'
        put api("/application/settings", admin), params: { whats_new_variant: new_value }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['whats_new_variant']).to eq(new_value)
      end

      it 'fails to update setting with invalid value' do
        put api("/application/settings", admin), params: { whats_new_variant: 'invalid_value' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('whats_new_variant does not have a valid value')
      end
    end

    context 'sidekiq job limit settings' do
      it 'updates the settings' do
        settings = {
          sidekiq_job_limiter_mode: 'track',
          sidekiq_job_limiter_compression_threshold_bytes: 1,
          sidekiq_job_limiter_limit_bytes: 2
        }.stringify_keys

        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.slice(*settings.keys)).to eq(settings)
      end
    end

    context 'Sentry settings' do
      let(:settings) do
        {
          sentry_enabled: true,
          sentry_dsn: 'http://sentry.example.com',
          sentry_clientside_dsn: 'http://sentry.example.com',
          sentry_environment: 'production',
          sentry_clientside_traces_sample_rate: 0.25
        }
      end

      let(:attribute_names) { settings.keys.map(&:to_s) }

      it 'includes the attributes in the API' do
        get api('/application/settings', admin)

        expect(response).to have_gitlab_http_status(:ok)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api('/application/settings', admin), params: settings

        expect(response).to have_gitlab_http_status(:ok)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      context 'missing sentry_dsn value when sentry_enabled is true' do
        it 'returns a blank parameter error message' do
          put api('/application/settings', admin), params: { sentry_enabled: true }

          expect(response).to have_gitlab_http_status(:bad_request)
          message = json_response['message']
          expect(message["sentry_dsn"]).to include(a_string_matching("can't be blank"))
        end
      end
    end

    context 'with enabled_git_access_protocol' do
      %w[ssh http].each do |protocol|
        it "allows #{protocol}" do
          put api('/application/settings', admin), params: {
            enabled_git_access_protocol: protocol
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['enabled_git_access_protocol']).to eq(protocol)
          expect(ApplicationSetting.current.enabled_git_access_protocol).to eq(protocol)
        end
      end

      it 'allows "all"' do
        put api('/application/settings', admin), params: {
          enabled_git_access_protocol: 'all'
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['enabled_git_access_protocol']).to eq('')
        expect(ApplicationSetting.current.enabled_git_access_protocol).to eq('')
      end
    end

    context 'runner token expiration_intervals' do
      it 'updates the settings' do
        put api("/application/settings", admin), params: {
          runner_token_expiration_interval: 3600,
          group_runner_token_expiration_interval: 3600 * 2,
          project_runner_token_expiration_interval: 3600 * 3
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'runner_token_expiration_interval' => 3600,
          'group_runner_token_expiration_interval' => 3600 * 2,
          'project_runner_token_expiration_interval' => 3600 * 3
        )
      end

      it 'updates the settings with empty values' do
        put api("/application/settings", admin), params: {
          runner_token_expiration_interval: nil,
          group_runner_token_expiration_interval: nil,
          project_runner_token_expiration_interval: nil
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'runner_token_expiration_interval' => nil,
          'group_runner_token_expiration_interval' => nil,
          'project_runner_token_expiration_interval' => nil
        )
      end
    end

    context 'with pipeline_limit_per_project_user_sha' do
      it 'updates the settings' do
        put api("/application/settings", admin), params: {
          pipeline_limit_per_project_user_sha: 25
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'pipeline_limit_per_project_user_sha' => 25
        )
      end

      it 'updates the settings with zero value' do
        put api("/application/settings", admin), params: {
          pipeline_limit_per_project_user_sha: 0
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'pipeline_limit_per_project_user_sha' => 0
        )
      end

      it 'does not allow null values' do
        put api("/application/settings", admin), params: {
          pipeline_limit_per_project_user_sha: nil
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['pipeline_limit_per_project_user_sha'])
          .to include(a_string_matching('is not a number'))
      end
    end

    context 'with ci_max_includes' do
      it 'updates the settings' do
        put api("/application/settings", admin), params: {
          ci_max_includes: 200
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'ci_max_includes' => 200
        )
      end

      it 'allows a zero value' do
        put api("/application/settings", admin), params: {
          ci_max_includes: 0
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'ci_max_includes' => 0
        )
      end

      it 'does not allow a nil value' do
        put api("/application/settings", admin), params: {
          ci_max_includes: nil
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['ci_max_includes'])
          .to include(a_string_matching('is not a number'))
      end
    end

    context 'with downstream_pipeline_trigger_limit_per_project_user_sha' do
      it 'updates the settings' do
        put api("/application/settings", admin), params: {
          downstream_pipeline_trigger_limit_per_project_user_sha: 200
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'downstream_pipeline_trigger_limit_per_project_user_sha' => 200
        )
      end

      it 'allows a zero value' do
        put api("/application/settings", admin), params: {
          downstream_pipeline_trigger_limit_per_project_user_sha: 0
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'downstream_pipeline_trigger_limit_per_project_user_sha' => 0
        )
      end

      it 'does not allow a nil value' do
        put api("/application/settings", admin), params: {
          downstream_pipeline_trigger_limit_per_project_user_sha: nil
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['downstream_pipeline_trigger_limit_per_project_user_sha'])
          .to include(a_string_matching('is not a number'))
      end
    end

    context 'with housekeeping enabled' do
      it 'at least one of housekeeping_incremental_repack_period or housekeeping_optimize_repository_period is required' do
        put api("/application/settings", admin), params: {
          housekeeping_enabled: true
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(
          "housekeeping_incremental_repack_period, housekeeping_optimize_repository_period are missing, exactly one parameter must be provided"
        )
      end

      context 'when housekeeping_incremental_repack_period is specified' do
        it 'requires all three housekeeping settings' do
          put api("/application/settings", admin), params: {
            housekeeping_enabled: true,
            housekeeping_incremental_repack_period: 10
          }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq(
            "housekeeping_full_repack_period, housekeeping_gc_period, housekeeping_incremental_repack_period provide all or none of parameters"
          )
        end

        it 'returns housekeeping_optimize_repository_period value for all housekeeping settings attributes' do
          put api("/application/settings", admin), params: {
            housekeeping_enabled: true,
            housekeeping_gc_period: 150,
            housekeeping_full_repack_period: 125,
            housekeeping_incremental_repack_period: 100
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['housekeeping_optimize_repository_period']).to eq(100)
          expect(json_response['housekeeping_full_repack_period']).to eq(100)
          expect(json_response['housekeeping_gc_period']).to eq(100)
          expect(json_response['housekeeping_incremental_repack_period']).to eq(100)
        end
      end

      context 'when housekeeping_optimize_repository_period is specified' do
        it 'returns housekeeping_optimize_repository_period value for all housekeeping settings attributes' do
          put api("/application/settings", admin), params: {
            housekeeping_enabled: true,
            housekeeping_optimize_repository_period: 100
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['housekeeping_optimize_repository_period']).to eq(100)
          expect(json_response['housekeeping_full_repack_period']).to eq(100)
          expect(json_response['housekeeping_gc_period']).to eq(100)
          expect(json_response['housekeeping_incremental_repack_period']).to eq(100)
        end
      end
    end

    context 'login attempts lock settings' do
      it 'updates the settings' do
        put(
          api("/application/settings", admin),
          params: { max_login_attempts: 3,
                    failed_login_attempts_unlock_period_in_minutes: 30 }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['max_login_attempts']).to eq(3)
        expect(json_response['failed_login_attempts_unlock_period_in_minutes']).to eq(30)
      end
    end

    context 'security txt settings' do
      let(:content) { "Contact: foo@acme.com" }

      it 'updates the settings' do
        put(
          api("/application/settings", admin),
          params: { security_txt_content: content }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['security_txt_content']).to eq(content)
      end
    end

    context 'with resource usage limits' do
      let(:hash) do
        {
          'rules' => [
            {
              'name' => 'test',
              'rules' => [{ 'interval' => 1, 'threshold' => 10, 'selector' => '*' }],
              'resource_key' => 'key',
              'metadata' => {},
              'scopes' => ['worker_name']
            }
          ]
        }
      end

      it 'updates the settings' do
        put(
          api("/application/settings", admin),
          params: { resource_usage_limits: Gitlab::Json.dump(hash) }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['resource_usage_limits']).to eq(hash)
      end
    end
  end
end
