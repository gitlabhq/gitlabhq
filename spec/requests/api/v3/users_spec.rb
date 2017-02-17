require 'spec_helper'

describe API::V3::Users, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }
  let(:email)   { create(:email, user: user) }

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
end
