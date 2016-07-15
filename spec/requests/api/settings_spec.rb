require 'spec_helper'

describe API::API, 'Settings', api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe "GET /application/settings" do
    it "should return application settings" do
      get api("/application/settings", admin)
      expect(response).to have_http_status(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['signin_enabled']).to be_truthy
      expect(json_response['repository_storage']).to eq('default')
    end
  end

  describe "PUT /application/settings" do
    before do
      storages = { 'custom' => 'tmp/tests/custom_repositories' }
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    it "should update application settings" do
      put api("/application/settings", admin),
        default_projects_limit: 3, signin_enabled: false, repository_storage: 'custom'
      expect(response).to have_http_status(200)
      expect(json_response['default_projects_limit']).to eq(3)
      expect(json_response['signin_enabled']).to be_falsey
      expect(json_response['repository_storage']).to eq('custom')
    end
  end
end
