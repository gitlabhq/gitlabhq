# frozen_string_literal: true

RSpec.shared_examples 'allows the "read_user" scope' do |api_version|
  let(:version) { api_version || 'v4' }

  context 'for personal access tokens' do
    context 'when the requesting token has the "api" scope' do
      let(:token) { create(:personal_access_token, scopes: ['api'], user: user) }

      it 'returns a "200" response on get request' do
        get api_call.call(path, user, personal_access_token: token, version: version)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a "200" response on head request' do
        head api_call.call(path, user, personal_access_token: token, version: version)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the requesting token has the "read_user" scope' do
      let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

      it 'returns a "200" response on get request' do
        get api_call.call(path, user, personal_access_token: token, version: version)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a "200" response on head request' do
        head api_call.call(path, user, personal_access_token: token, version: version)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the requesting token does not have any required scope' do
      let(:token) { create(:personal_access_token, scopes: ['read_registry'], user: user) }

      before do
        stub_container_registry_config(enabled: true)
      end

      it 'returns a "403" response' do
        get api_call.call(path, user, personal_access_token: token, version: version)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'for doorkeeper (OAuth) tokens' do
    let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }

    context 'when the requesting token has the "api" scope' do
      let!(:token) do
        Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "api", organization_id: user.namespace.organization.id
      end

      it 'returns a "200" response on get request' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a "200" response on head request' do
        head api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the requesting token has the "read_user" scope' do
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "read_user", organization_id: user.namespace.organization.id }

      it 'returns a "200" response on get request' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a "200" response on head request' do
        head api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the requesting token does not have any required scope' do
      let!(:token) { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id, scopes: "invalid", organization_id: user.namespace.organization.id }

      it 'returns a "403" response' do
        get api_call.call(path, user, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end

RSpec.shared_examples 'does not allow the "read_user" scope' do
  context 'when the requesting token has the "read_user" scope' do
    let(:token) { create(:personal_access_token, scopes: ['read_user'], user: user) }

    it 'returns a "403" response' do
      post api_call.call(path, user, personal_access_token: token), params: attributes_for(:user, projects_limit: 3)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
