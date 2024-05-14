# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwksController, feature_category: :system_access do
  describe 'Endpoints from the parent Doorkeeper::OpenidConnect::DiscoveryController' do
    it 'respond successfully' do
      [
        "/oauth/discovery/keys",
        "/.well-known/openid-configuration",
        "/.well-known/webfinger?resource=#{create(:user).email}"
      ].each do |endpoint|
        get endpoint

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
