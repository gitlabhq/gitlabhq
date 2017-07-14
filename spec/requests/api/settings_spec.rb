require 'spec_helper'

describe API::Settings, 'Settings' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get api("/application/settings", admin)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['signin_enabled']).to be_truthy
      expect(json_response['repository_storages']).to eq(['default'])
      expect(json_response['password_authentication_enabled']).to be_truthy
      expect(json_response['koding_enabled']).to be_falsey
      expect(json_response['koding_url']).to be_nil
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
      expect(json_response['default_project_visibility']).to be_a String
      expect(json_response['default_snippet_visibility']).to be_a String
      expect(json_response['default_group_visibility']).to be_a String
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
          repository_storages: ['custom'],
          password_authentication_enabled: false,
          koding_enabled: true,
          koding_url: 'http://koding.example.com',
          plantuml_enabled: true,
          plantuml_url: 'http://plantuml.example.com',
          default_snippet_visibility: 'internal',
          restricted_visibility_levels: ['public'],
          default_artifacts_expire_in: '2 days',
          help_page_text: 'custom help text',
          help_page_hide_commercial_content: true,
          help_page_support_url: 'http://example.com/help'
        expect(response).to have_http_status(200)
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['signin_enabled']).to be_falsey
        expect(json_response['password_authentication_enabled']).to be_falsey
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
      end
    end

    context "missing koding_url value when koding_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), koding_enabled: true

        expect(response).to have_http_status(400)
        expect(json_response['error']).to eq('koding_url is missing')
      end
    end

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), plantuml_enabled: true

        expect(response).to have_http_status(400)
        expect(json_response['error']).to eq('plantuml_url is missing')
      end
    end
  end
end
