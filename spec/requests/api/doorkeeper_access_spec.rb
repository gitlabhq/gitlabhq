require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let!(:user) { create(:user) }
  let!(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
  let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: 'api' }

  describe 'when unauthenticated' do
    it 'returns authentication success' do
      get api('/user'), access_token: token.token
      expect(response).to have_http_status(200)
    end

    include_context 'limit login to only one ip' do
      it 'allows login twice from the same ip' do
        get api('/user'), access_token: token.token
        expect(response).to have_http_status(200)

        get api('/user'), access_token: token.token
        expect(response).to have_http_status(200)
      end

      it 'blocks login from two different ips' do
        get api('/user'), access_token: token.token
        expect(response).to have_http_status(200)

        change_ip('ip2')
        get api('/user'), access_token: token.token
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'when token invalid' do
    it 'returns authentication error' do
      get api('/user'), access_token: '123a'
      expect(response).to have_http_status(401)
    end
  end

  describe 'authorization by private token' do
    it 'returns authentication success' do
      get api('/user', user)
      expect(response).to have_http_status(200)
    end

    include_context 'limit login to only one ip' do
      it 'allows login twice from the same ip' do
        get api('/user', user)
        expect(response).to have_http_status(200)

        get api('/user', user)
        expect(response).to have_http_status(200)
      end

      it 'blocks login from two different ips' do
        get api('/user', user)
        expect(response).to have_http_status(200)

        change_ip('ip2')
        get api('/user', user)
        expect(response).to have_http_status(403)
      end
    end
  end
end
