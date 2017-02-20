require 'spec_helper'

describe API::V3::Users, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }
  let(:email)   { create(:email, user: user) }
  let(:ldap_blocked_user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }

  describe 'GET /user/:id/keys' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api("/users/#{user.id}/keys")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get v3_api('/users/999999/keys', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of ssh keys' do
        user.keys << key
        user.save

        get v3_api("/users/#{user.id}/keys", admin)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(key.title)
      end
    end
  end

  describe 'GET /user/:id/emails' do
    before { admin }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api("/users/#{user.id}/emails")
        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns 404 for non-existing user' do
        get v3_api('/users/999999/emails', admin)
        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns array of emails' do
        user.emails << email
        user.save

        get v3_api("/users/#{user.id}/emails", admin)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['email']).to eq(email.email)
      end

      it "returns a 404 for invalid ID" do
        put v3_api("/users/ASDF/emails", admin)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /user/keys" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/user/keys")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of ssh keys" do
        user.keys << key
        user.save

        get v3_api("/user/keys", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first["title"]).to eq(key.title)
      end
    end
  end

  describe "GET /user/emails" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/user/emails")
        expect(response).to have_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns array of emails" do
        user.emails << email
        user.save

        get v3_api("/user/emails", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first["email"]).to eq(email.email)
      end
    end
  end

  describe 'PUT /users/:id/block' do
    before { admin }
    it 'blocks existing user' do
      put v3_api("/users/#{user.id}/block", admin)
      expect(response).to have_http_status(200)
      expect(user.reload.state).to eq('blocked')
    end

    it 'does not re-block ldap blocked users' do
      put v3_api("/users/#{ldap_blocked_user.id}/block", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      put v3_api("/users/#{user.id}/block", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      put v3_api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end
  end

  describe 'PUT /users/:id/unblock' do
    let(:blocked_user)  { create(:user, state: 'blocked') }
    before { admin }

    it 'unblocks existing user' do
      put v3_api("/users/#{user.id}/unblock", admin)
      expect(response).to have_http_status(200)
      expect(user.reload.state).to eq('active')
    end

    it 'unblocks a blocked user' do
      put v3_api("/users/#{blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(200)
      expect(blocked_user.reload.state).to eq('active')
    end

    it 'does not unblock ldap blocked users' do
      put v3_api("/users/#{ldap_blocked_user.id}/unblock", admin)
      expect(response).to have_http_status(403)
      expect(ldap_blocked_user.reload.state).to eq('ldap_blocked')
    end

    it 'does not be available for non admin users' do
      put v3_api("/users/#{user.id}/unblock", user)
      expect(response).to have_http_status(403)
      expect(user.reload.state).to eq('active')
    end

    it 'returns a 404 error if user id not found' do
      put v3_api('/users/9999/block', admin)
      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 User Not Found')
    end

    it "returns a 404 for invalid ID" do
      put v3_api("/users/ASDF/block", admin)

      expect(response).to have_http_status(404)
    end
  end
end
