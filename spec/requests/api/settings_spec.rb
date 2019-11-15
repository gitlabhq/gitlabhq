# frozen_string_literal: true

require 'spec_helper'

describe API::Settings, 'Settings' do
  let(:user) { create(:user) }
  set(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get api("/application/settings", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['password_authentication_enabled_for_web']).to be_truthy
      expect(json_response['repository_storages']).to eq(['default'])
      expect(json_response['password_authentication_enabled']).to be_truthy
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
      expect(json_response['default_ci_config_path']).to be_nil
      expect(json_response['sourcegraph_enabled']).to be_falsey
      expect(json_response['sourcegraph_url']).to be_nil
      expect(json_response['sourcegraph_public_only']).to be_truthy
      expect(json_response['default_project_visibility']).to be_a String
      expect(json_response['default_snippet_visibility']).to be_a String
      expect(json_response['default_group_visibility']).to be_a String
      expect(json_response['rsa_key_restriction']).to eq(0)
      expect(json_response['dsa_key_restriction']).to eq(0)
      expect(json_response['ecdsa_key_restriction']).to eq(0)
      expect(json_response['ed25519_key_restriction']).to eq(0)
      expect(json_response['performance_bar_allowed_group_id']).to be_nil
      expect(json_response['instance_statistics_visibility_private']).to be(false)
      expect(json_response['allow_local_requests_from_hooks_and_services']).to be(false)
      expect(json_response['allow_local_requests_from_web_hooks_and_services']).to be(false)
      expect(json_response['allow_local_requests_from_system_hooks']).to be(true)
      expect(json_response).not_to have_key('performance_bar_allowed_group_path')
      expect(json_response).not_to have_key('performance_bar_enabled')
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
        Feature.get(:sourcegraph).enable
      end

      it "updates application settings" do
        put api("/application/settings", admin),
          params: {
            default_ci_config_path: 'debian/salsa-ci.yml',
            default_projects_limit: 3,
            default_project_creation: 2,
            password_authentication_enabled_for_web: false,
            repository_storages: ['custom'],
            plantuml_enabled: true,
            plantuml_url: 'http://plantuml.example.com',
            sourcegraph_enabled: true,
            sourcegraph_url: 'https://sourcegraph.com',
            sourcegraph_public_only: false,
            default_snippet_visibility: 'internal',
            restricted_visibility_levels: ['public'],
            default_artifacts_expire_in: '2 days',
            help_page_text: 'custom help text',
            help_page_hide_commercial_content: true,
            help_page_support_url: 'http://example.com/help',
            project_export_enabled: false,
            rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE,
            dsa_key_restriction: 2048,
            ecdsa_key_restriction: 384,
            ed25519_key_restriction: 256,
            enforce_terms: true,
            terms: 'Hello world!',
            performance_bar_allowed_group_path: group.full_path,
            instance_statistics_visibility_private: true,
            diff_max_patch_bytes: 150_000,
            default_branch_protection: ::Gitlab::Access::PROTECTION_DEV_CAN_MERGE,
            local_markdown_version: 3,
            allow_local_requests_from_web_hooks_and_services: true,
            allow_local_requests_from_system_hooks: false,
            push_event_hooks_limit: 2,
            push_event_activities_limit: 2
          }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['default_ci_config_path']).to eq('debian/salsa-ci.yml')
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['default_project_creation']).to eq(::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
        expect(json_response['password_authentication_enabled_for_web']).to be_falsey
        expect(json_response['repository_storages']).to eq(['custom'])
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
        expect(json_response['project_export_enabled']).to be_falsey
        expect(json_response['rsa_key_restriction']).to eq(ApplicationSetting::FORBIDDEN_KEY_VALUE)
        expect(json_response['dsa_key_restriction']).to eq(2048)
        expect(json_response['ecdsa_key_restriction']).to eq(384)
        expect(json_response['ed25519_key_restriction']).to eq(256)
        expect(json_response['enforce_terms']).to be(true)
        expect(json_response['terms']).to eq('Hello world!')
        expect(json_response['performance_bar_allowed_group_id']).to eq(group.id)
        expect(json_response['instance_statistics_visibility_private']).to be(true)
        expect(json_response['diff_max_patch_bytes']).to eq(150_000)
        expect(json_response['default_branch_protection']).to eq(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)
        expect(json_response['local_markdown_version']).to eq(3)
        expect(json_response['allow_local_requests_from_web_hooks_and_services']).to eq(true)
        expect(json_response['allow_local_requests_from_system_hooks']).to eq(false)
        expect(json_response['push_event_hooks_limit']).to eq(2)
        expect(json_response['push_event_activities_limit']).to eq(2)
      end
    end

    it "supports legacy performance_bar_allowed_group_id" do
      put api("/application/settings", admin),
        params: { performance_bar_allowed_group_id: group.full_path }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['performance_bar_allowed_group_id']).to eq(group.id)
    end

    it "supports legacy performance_bar_enabled" do
      put api("/application/settings", admin),
        params: {
          performance_bar_enabled: false,
          performance_bar_allowed_group_id: group.full_path
        }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['performance_bar_allowed_group_id']).to be_nil
    end

    it 'supports legacy allow_local_requests_from_hooks_and_services' do
      put api("/application/settings", admin),
          params: { allow_local_requests_from_hooks_and_services: true }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['allow_local_requests_from_hooks_and_services']).to eq(true)
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

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(200)
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
          snowplow_app_id: "app_id",
          snowplow_iglu_registry_url: 'https://example.com'
        }
      end

      let(:attribute_names) { settings.keys.map(&:to_s) }

      it "includes the attributes in the API" do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it "allows updating the settings" do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(200)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      context "missing snowplow_collector_hostname value when snowplow_enabled is true" do
        it "returns a blank parameter error message" do
          put api("/application/settings", admin), params: { snowplow_enabled: true }

          expect(response).to have_gitlab_http_status(400)
          expect(json_response["error"]).to eq("snowplow_collector_hostname is missing")
        end

        it "handles validation errors" do
          put api("/application/settings", admin), params: settings.merge({
            snowplow_collector_hostname: nil
          })

          expect(response).to have_gitlab_http_status(400)
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

        expect(response).to have_gitlab_http_status(200)
        exposed_attributes.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'does not include sensitive attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        sensitive_attributes.each do |attribute|
          expect(json_response.keys).not_to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), params: settings

        expect(response).to have_gitlab_http_status(200)
        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end

      context 'EKS integration is enabled but params are blank' do
        let(:settings) { Hash[eks_integration_enabled: true] }

        it 'does not update the settings' do
          put api("/application/settings", admin), params: settings

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['error']).to include('eks_account_id is missing')
          expect(json_response['error']).to include('eks_access_key_id is missing')
          expect(json_response['error']).to include('eks_secret_access_key is missing')
        end
      end
    end

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { plantuml_enabled: true }

        expect(response).to have_gitlab_http_status(400)
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
            asset_proxy_whitelist: ['example.com', '*.example.com']
          }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['asset_proxy_enabled']).to be(true)
        expect(json_response['asset_proxy_url']).to eq('http://assets.example.com')
        expect(json_response['asset_proxy_secret_key']).to be_nil
        expect(json_response['asset_proxy_whitelist']).to eq(['example.com', '*.example.com', 'localhost'])
      end

      it 'allows a string for asset_proxy_whitelist' do
        put api('/application/settings', admin),
          params: {
            asset_proxy_whitelist: 'example.com, *.example.com'
          }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['asset_proxy_whitelist']).to eq(['example.com', '*.example.com', 'localhost'])
      end
    end

    context 'domain_blacklist settings' do
      it 'rejects domain_blacklist_enabled when domain_blacklist is empty' do
        put api('/application/settings', admin),
          params: {
            domain_blacklist_enabled: true,
            domain_blacklist: []
          }

        expect(response).to have_gitlab_http_status(400)
        message = json_response["message"]
        expect(message["domain_blacklist"]).to eq(["Domain blacklist cannot be empty if Blacklist is enabled."])
      end

      it 'allows array for domain_blacklist' do
        put api('/application/settings', admin),
          params: {
            domain_blacklist_enabled: true,
            domain_blacklist: ['domain1.com', 'domain2.com']
          }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['domain_blacklist_enabled']).to be(true)
        expect(json_response['domain_blacklist']).to eq(['domain1.com', 'domain2.com'])
      end

      it 'allows a string for domain_blacklist' do
        put api('/application/settings', admin),
          params: {
            domain_blacklist_enabled: true,
            domain_blacklist: 'domain3.com, *.domain4.com'
          }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['domain_blacklist_enabled']).to be(true)
        expect(json_response['domain_blacklist']).to eq(['domain3.com', '*.domain4.com'])
      end
    end

    context "missing sourcegraph_url value when sourcegraph_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), params: { sourcegraph_enabled: true }

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('sourcegraph_url is missing')
      end
    end
  end
end
