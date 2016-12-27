require 'spec_helper'

describe API::PersonalAccessTokens, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }

  describe "GET /personal_access_tokens" do
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
    let!(:revoked_personal_access_token) { create(:revoked_personal_access_token, user: user) }
    let!(:expired_personal_access_token) { create(:expired_personal_access_token, user: user) }

    it 'returns an array of personal access tokens without exposing the token' do
      get api("/personal_access_tokens", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(3)

      json_personal_access_token = json_response.detect do |personal_access_token|
        personal_access_token['id'] == active_personal_access_token.id
      end

      expect(json_personal_access_token['name']).to eq(active_personal_access_token.name)
      expect(json_personal_access_token['token']).not_to be_present
    end

    it 'returns an array of active personal access tokens if active is set to true' do
      get api("/personal_access_tokens?state=active", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response).to all(include('active' => true))
    end

    it 'returns an array of inactive personal access tokens if active is set to false' do
      get api("/personal_access_tokens?state=inactive", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response).to all(include('active' => false))
    end
  end

  describe 'POST /personal_access_tokens' do
    let(:name) { 'my new pat' }
    let(:expires_at) { '2016-12-28' }
    let(:scopes) { ['api', 'read_user'] }

    it 'returns validation error if personal access token miss some attributes' do
      post api("/personal_access_tokens", user)

      expect(response).to have_http_status(400)
      expect(json_response['error']).to eq('name is missing')
    end

    it 'creates a personal access token' do
      post api("/personal_access_tokens", user),
        name: name,
        expires_at: expires_at,
        scopes: scopes

      expect(response).to have_http_status(201)

      personal_access_token_id = json_response['id']

      expect(json_response['name']).to eq(name)
      expect(json_response['scopes']).to eq(scopes)
      expect(json_response['expires_at']).to eq(expires_at)
      expect(json_response['id']).to be_present
      expect(json_response['created_at']).to be_present
      expect(json_response['active']).to eq(false)
      expect(json_response['revoked']).to eq(false)
      expect(json_response['token']).to be_present
      expect(PersonalAccessToken.find(personal_access_token_id)).not_to eq(nil)
    end
  end

  describe 'DELETE /personal_access_tokens/:personal_access_token_id' do
    let!(:personal_access_token) { create(:personal_access_token, user: user, revoked: false) }
    let!(:personal_access_token_of_another_user) { create(:personal_access_token, revoked: false) }

    it 'returns a 404 error if personal access token not found' do
      delete api("/personal_access_tokens/42", user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 PersonalAccessToken Not Found')
    end

    it 'returns a 404 error if personal access token exists but it is a personal access tokens of another user' do
      delete api("/personal_access_tokens/#{personal_access_token_of_another_user.id}", user)

      expect(response).to have_http_status(404)
      expect(json_response['message']).to eq('404 PersonalAccessToken Not Found')
    end

    it 'revokes a personal access token and does not expose token in the json response' do
      delete api("/personal_access_tokens/#{personal_access_token.id}", user)

      expect(response).to have_http_status(200)
      expect(personal_access_token.revoked).to eq(false)
      expect(personal_access_token.reload.revoked).to eq(true)
      expect(json_response['revoked']).to eq(true)
      expect(json_response['token']).not_to be_present
    end
  end
end
