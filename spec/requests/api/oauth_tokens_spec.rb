require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  context 'Resource Owner Password Credentials' do
    def request_oauth_token(user)
      post '/oauth/token', username: user.username, password: user.password, grant_type: 'password'
    end

    context 'when user has 2FA enabled' do
      it 'does not create an access token' do
        user = create(:user, :two_factor)
        request_oauth_token(user)

        expect(response).to have_http_status(401)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end

    context 'when user does not have 2FA enabled' do
      it 'creates an access token' do
        user = create(:user)
        request_oauth_token(user)

        expect(response).to have_http_status(200)
        expect(json_response['access_token']).not_to be_nil
      end
    end
  end
end