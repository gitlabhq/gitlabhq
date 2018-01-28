require 'spec_helper'

describe API::V3::Settings, 'Settings' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get v3_api("/application/settings", admin)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['password_authentication_enabled']).to be_truthy
      expect(json_response['repository_storage']).to eq('default')
      expect(json_response['koding_enabled']).to be_falsey
      expect(json_response['koding_url']).to be_nil
      expect(json_response['plantuml_enabled']).to be_falsey
      expect(json_response['plantuml_url']).to be_nil
    end
  end

  describe "PUT /application/settings" do
    context "custom repository storage type set in the config" do
      before do
        storages = { 'custom' => 'tmp/tests/custom_repositories' }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      end

      it "updates application settings" do
        put v3_api("/application/settings", admin),
          default_projects_limit: 3, password_authentication_enabled_for_web: false, repository_storage: 'custom', koding_enabled: true, koding_url: 'http://koding.example.com',
          plantuml_enabled: true, plantuml_url: 'http://plantuml.example.com'
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['password_authentication_enabled_for_web']).to be_falsey
        expect(json_response['repository_storage']).to eq('custom')
        expect(json_response['repository_storages']).to eq(['custom'])
        expect(json_response['koding_enabled']).to be_truthy
        expect(json_response['koding_url']).to eq('http://koding.example.com')
        expect(json_response['plantuml_enabled']).to be_truthy
        expect(json_response['plantuml_url']).to eq('http://plantuml.example.com')
      end
    end

    context "missing koding_url value when koding_enabled is true" do
      it "returns a blank parameter error message" do
        put v3_api("/application/settings", admin), koding_enabled: true

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('koding_url is missing')
      end
    end

    context "missing plantuml_url value when plantuml_enabled is true" do
      it "returns a blank parameter error message" do
        put v3_api("/application/settings", admin), plantuml_enabled: true

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('plantuml_url is missing')
      end
    end
  end
end
