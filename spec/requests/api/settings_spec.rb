# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Settings, 'Settings', :do_not_mock_admin_mode_setting do
  let(:user) { create(:user) }

  let_it_be(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get api("/application/settings", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['password_authentication_enabled_for_web']).to be_truthy
      expect(json_response['repository_storages_weighted']).to eq({ 'default' => 100 })
      expect(json_response['password_authentication_enabled']).to be_truthy
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
      expect(json_response['default_ci_config_path']).to be_nil
      expect(json_response['sourcegraph_enabled']).to be_falsey
      expect(json_response['sourcegraph_url']).to be_nil
      expect(json_response['secret_detection_token_revocation_url']).to be_nil
      expect(json_response['secret_detection_revocation_token_types_url']).to be_nil
      expect(json_response['sourcegraph_public_only']).to be_truthy
      expect(json_response['default_project_visibility']).to be_a String
      expect(json_response['default_snippet_visibility']).to be_a String
      expect(json_response['default_group_visibility']).to be_a String
      expect(json_response['rsa_key_restriction']).to eq(0)
      expect(json_response['dsa_key_restriction']).to eq(0)
      expect(json_response['ecdsa_key_restriction']).to eq(0)
      expect(json_response['ed25519_key_restriction']).to eq(0)
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
      expect(json_response['require_admin_approval_after_user_signup']).to eq(true)
      expect(json_response['personal_access_token_prefix']).to be_nil
      expect(json_response['admin_mode']).to be(false)
      expect(json_response['whats_new_variant']).to eq('all_tiers')
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
        expect(json_response['repository_storages_weighted']).to eq({ 'custom' => 75 })
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

      it "updates application settings" do
        put api("/application/settings", admin),
          params: {
            default_ci_config_path: 'debian/salsa-ci.yml',
            default_projects_limit: 3,
            default_project_creation: 2,
            password_authentication_enabled_for_web: false,
            repository_storages_weighted: { 'custom' => 100 },
            plantuml_enabled: true,
            plantuml_url: 'http://plantuml.example.com',
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
            enforce_terms: true,
            terms: 'Hello world!',
            performance_bar_allowed_group_path: group.full_path,
            diff_max_patch_bytes: 300_000,
            diff_max_files: 2000,
            diff_max_lines: 50000,
            default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE,
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
            disabled_oauth_sign_in_sources: 'unknown',
            import_sources: 'github,bitbucket',
            wiki_page_max_content_bytes: 12345,
            personal_access_token_prefix: "GL-",
            admin_mode: true
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['default_ci_config_path']).to eq('debian/salsa-ci.yml')
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['default_project_creation']).to eq(::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
        expect(json_response['password_authentication_enabled_for_web']).to be_falsey
        expect(json_response['repository_storages_weighted']).to eq({ 'custom' => 100 })
        expect(json_response['plantuml_enabled']).to be_truthy
        expect(json_response['plantuml_url']).to eq('http://plantuml.example.com')
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
        expect(json_response['enforce_terms']).to be(true)
        expect(json_response['terms']).to eq('Hello world!')
        expect(json_response['performance_bar_allowed_group_id']).to eq(group.id)
        expect(json_response['diff_max_patch_bytes']).to eq(300_000)
        expect(json_response['diff_max_files']).to eq(2000)
        expect(json_response['diff_max_lines']).to eq(50000)
        expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
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
        expect(json_response['disabled_oauth_sign_in_sources']).to eq([])
        expect(json_response['import_sources']).to match_array(%w(github bitbucket))
        expect(json_response['wiki_page_max_content_bytes']).to eq(12345)
        expect(json_response['personal_access_token_prefix']).to eq("GL-")
        expect(json_response['admin_mode']).to be(true)
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

    it 'disables ability to switch to legacy storage' do
      put api("/application/settings", admin),
          params: { hashed_storage_enabled: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['hashed_storage_enabled']).to eq(true)
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

    context "snowplow tracking settings" do
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
      let(:sensitive_attributes) { %w(eks_secret_access_key) }
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

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { plantuml_enabled: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('plantuml_url is missing')
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

    context "missing spam_check_api_key value when spam_check_endpoint_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { spam_check_endpoint_enabled: true, spam_check_endpoint_url: "https://example.com/spam_check" }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('spam_check_api_key is missing')
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
        put api("/application/settings", admin),
        params: {
          whats_new_variant: new_value
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['whats_new_variant']).to eq(new_value)
      end

      it 'fails to update setting with invalid value' do
        put api("/application/settings", admin),
        params: {
          whats_new_variant: 'invalid_value'
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('whats_new_variant does not have a valid value')
      end
    end
  end
end
