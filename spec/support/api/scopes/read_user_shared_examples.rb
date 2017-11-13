shared_examples_for 'allows the "read_user" scope' do
  context 'for personal access tokens' do
    context 'when the requesting token has the "api" scope' do
      let(:token) { create(:personal_access_token, scopes: ['api'], user: user) }

      it 'returns a "200" response' do
        get api_call.call(path, user, personal_access_token: token)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the requesting token has the "read_user" scope' do
      let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

      it 'returns a "200" response' do
        get api_call.call(path, user, personal_access_token: token)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the requesting token does not have any required scope' do
      let(:token) { create(:personal_access_token, scopes: ['read_registry'], user: user) }

      before do
        stub_container_registry_config(enabled: true)
      end

      it 'returns a "403" response' do
        get api_call.call(path, user, personal_access_token: token)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  context 'for doorkeeper (OAuth) tokens' do
    let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }

    context 'when the requesting token has the "api" scope' do
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "api" }

      it 'returns a "200" response' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the requesting token has the "read_user" scope' do
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "read_user" }

      it 'returns a "200" response' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the requesting token does not have any required scope' do
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "invalid" }

      it 'returns a "403" response' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end

shared_examples_for 'does not allow the "read_user" scope' do
  context 'when the requesting token has the "read_user" scope' do
    let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

    it 'returns a "403" response' do
      post api_call.call(path, user, personal_access_token: token), attributes_for(:user, projects_limit: 3)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end
