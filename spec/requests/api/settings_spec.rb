require 'spec_helper'

describe API::API, 'Settings', api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }


  describe "GET /application/settings" do
    it "should return application settings" do
      get api("/application/settings", admin)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Hash
      expect(json_response['default_projects_limit']).to eq(42)
      expect(json_response['signin_enabled']).to be_truthy
    end
  end

  describe "PUT /application/settings" do
    it "should update application settings" do
      put api("/application/settings", admin),
        default_projects_limit: 3, signin_enabled: false
      expect(response.status).to eq(200)
      expect(json_response['default_projects_limit']).to eq(3)
      expect(json_response['signin_enabled']).to be_falsey
    end
  end
end
