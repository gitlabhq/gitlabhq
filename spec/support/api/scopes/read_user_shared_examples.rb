shared_examples_for 'allows the "read_user" scope' do
  describe 'when the requesting token has the "read_user" scope' do
    let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

    it 'returns a "200" response' do
      get api_call.call(path, user, personal_access_token: token)

      expect(response).to have_http_status(200)
    end
  end

  describe 'when the requesting token does not have any required scope' do
    let(:token) { create(:personal_access_token, scopes: ['read_registry'], user: user) }

    it 'returns a "401" response' do
      get api_call.call(path, user, personal_access_token: token)

      expect(response).to have_http_status(401)
    end
  end
end

shared_examples_for 'does not allow the "read_user" scope' do
  context 'when the requesting token has the "read_user" scope' do
    let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

    it 'returns a "401" response' do
      post api_call.call(path, user, personal_access_token: token), attributes_for(:user, projects_limit: 3)

      expect(response).to have_http_status(401)
    end
  end
end
