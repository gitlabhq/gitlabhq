require 'spec_helper'

describe API::Settings, 'Settings' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get api("/application/settings", admin)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['password_authentication_enabled_for_web']).to be_truthy
      expect(json_response['repository_storages']).to eq(['default'])
      expect(json_response['koding_enabled']).to be_falsey
      expect(json_response['koding_url']).to be_nil
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
      expect(json_response['default_project_visibility']).to be_a String
      expect(json_response['default_snippet_visibility']).to be_a String
      expect(json_response['default_group_visibility']).to be_a String
      expect(json_response['rsa_key_restriction']).to eq(0)
      expect(json_response['dsa_key_restriction']).to eq(0)
      expect(json_response['ecdsa_key_restriction']).to eq(0)
      expect(json_response['ed25519_key_restriction']).to eq(0)
      expect(json_response['circuitbreaker_failure_count_threshold']).not_to be_nil
    end
  end

  describe "PUT /application/settings" do
    context "custom repository storage type set in the config" do
      before do
        storages = { 'custom' => 'tmp/tests/custom_repositories' }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      end

      it "updates application settings" do
        put api("/application/settings", admin),
          default_projects_limit: 3,
          password_authentication_enabled_for_web: false,
          repository_storages: ['custom'],
          koding_enabled: true,
          koding_url: 'http://koding.example.com',
          plantuml_enabled: true,
          plantuml_url: 'http://plantuml.example.com',
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
          circuitbreaker_check_interval: 2

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['password_authentication_enabled_for_web']).to be_falsey
        expect(json_response['repository_storages']).to eq(['custom'])
        expect(json_response['koding_enabled']).to be_truthy
        expect(json_response['koding_url']).to eq('http://koding.example.com')
        expect(json_response['plantuml_enabled']).to be_truthy
        expect(json_response['plantuml_url']).to eq('http://plantuml.example.com')
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
        expect(json_response['circuitbreaker_check_interval']).to eq(2)
      end
    end

    context "missing koding_url value when koding_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), koding_enabled: true

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('koding_url is missing')
      end
    end

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), plantuml_enabled: true

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('plantuml_url is missing')
      end
    end
  end
end
