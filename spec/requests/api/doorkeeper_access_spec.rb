# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'doorkeeper access' do
  let!(:user) { create(:user) }
  let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "api" }

  describe "unauthenticated" do
    it "returns authentication success" do
      get api("/user"), params: { access_token: token.token }
      expect(response).to have_gitlab_http_status(:ok)
    end

    include_examples 'user login request with unique ip limit' do
      def request
        get api('/user'), params: { access_token: token.token }
      end
    end
  end

  describe "when token invalid" do
    it "returns authentication error" do
      get api("/user"), params: { access_token: "123a" }
      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe "authorization by OAuth token" do
    it "returns authentication success" do
      get api("/user", user)
      expect(response).to have_gitlab_http_status(:ok)
    end

    include_examples 'user login request with unique ip limit' do
      def request
        get api('/user', user)
      end
    end
  end

  shared_examples 'forbidden request' do
    it 'returns 403 response' do
      get api("/user"), params: { access_token: token.token }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context "when user is blocked" do
    before do
      user.block
    end

    it_behaves_like 'forbidden request'
  end

  context "when user is ldap_blocked" do
    before do
      user.ldap_block
    end

    it_behaves_like 'forbidden request'
  end

  context "when user is deactivated" do
    before do
      user.deactivate
    end

    it_behaves_like 'forbidden request'
  end

  context 'when user is blocked pending approval' do
    before do
      user.block_pending_approval
    end

    it_behaves_like 'forbidden request'
  end
end
