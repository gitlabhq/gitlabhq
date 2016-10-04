require 'spec_helper'

describe API::API, 'Settings', api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "returns application settings" do
      get api("/application/settings", admin)
      expect(response).to have_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['signin_enabled']).to be_truthy
      expect(json_response['repository_storage']).to eq('default')
      expect(json_response['koding_enabled']).to be_falsey
      expect(json_response['koding_url']).to be_nil
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
          default_projects_limit: 3, signin_enabled: false, repository_storage: 'custom', koding_enabled: true, koding_url: 'http://koding.example.com'
        expect(response).to have_http_status(200)
        expect(json_response['default_projects_limit']).to eq(3)
        expect(json_response['signin_enabled']).to be_falsey
        expect(json_response['repository_storage']).to eq('custom')
        expect(json_response['koding_enabled']).to be_truthy
        expect(json_response['koding_url']).to eq('http://koding.example.com')
      end
    end

    context "missing koding_url value when koding_enabled is true" do
      it "returns a blank parameter error message" do
        put api("/application/settings", admin), koding_enabled: true

        expect(response).to have_http_status(400)
        expect(json_response['message']).to have_key('koding_url')
        expect(json_response['message']['koding_url']).to include "can't be blank"
      end
    end
  end
end
