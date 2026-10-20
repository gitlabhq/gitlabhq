# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab OAuth2 authorization code flow for granular applications', :aggregate_failures,
  feature_category: :permissions do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:other_group) { create(:group, organization: organization) }
  let_it_be(:user) { create(:user, :with_namespace, organizations: [organization]) }
  let_it_be_with_reload(:application) do
    create(:oauth_application, :granular, scopes: 'api', redirect_uri: 'https://example.com/oauth/callback',
      boundary: Authz::Boundary.for(group), permissions: :read_group)
  end

  let(:authorization_params) do
    { client_id: application.uid, response_type: 'code', redirect_uri: application.redirect_uri, scope: 'api' }
  end

  let(:client_params) { { client_id: application.uid, client_secret: application.secret } }

  before_all do
    group.add_developer(user)
    other_group.add_developer(user)
  end

  before do
    sign_in(user)
  end

  def active_grant
    Authz::OauthConsentGrant.active_for_user_and_application(user.id, application.id)
  end

  def code_from(location)
    Addressable::URI.parse(location).query_values['code']
  end

  def exchange_code(code)
    post oauth_token_path, params: client_params.merge(
      grant_type: 'authorization_code', redirect_uri: application.redirect_uri, code: code
    )
    json_response
  end

  def refresh_token(refresh_token, extra_params = {})
    post oauth_token_path, params: client_params.merge(
      grant_type: 'refresh_token', refresh_token: refresh_token
    ).merge(extra_params)
    json_response
  end

  def get_group(group, access_token)
    get "/api/v4/groups/#{group.id}", headers: { 'Authorization' => "Bearer #{access_token}" }
  end

  it 'records the consent, mints granular tokens, keeps them granular on refresh and enforces the grant' do
    post '/oauth/authorize', params: authorization_params

    expect(response).to have_gitlab_http_status(:found)
    expect(active_grant).to be_doorkeeper

    token_response = exchange_code(code_from(response.location))

    expect(response).to have_gitlab_http_status(:ok)
    expect(token_response['scope']).to eq('granular')

    get_group(group, token_response['access_token'])
    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['id']).to eq(group.id)

    get_group(other_group, token_response['access_token'])
    expect(response).to have_gitlab_http_status(:forbidden)

    refreshed_response = refresh_token(token_response['refresh_token'])
    expect(response).to have_gitlab_http_status(:ok)
    expect(refreshed_response['scope']).to eq('granular')

    refresh_token(refreshed_response['refresh_token'], scope: 'granular api')
    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq('invalid_scope')

    delete oauth_authorized_application_path(application)
    expect(response).to have_gitlab_http_status(:found)
    expect(active_grant).to be_nil

    get_group(group, refreshed_response['access_token'])
    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  context 'when the application is trusted' do
    before do
      application.update!(trusted: true)
    end

    it 'records the consent without a screen and mints a granular token' do
      get '/oauth/authorize', params: authorization_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(active_grant).to be_trusted_auto_grant

      code = response.body[/code=([^&"'\s]+)/, 1]
      token_response = exchange_code(code)

      expect(response).to have_gitlab_http_status(:ok)
      expect(token_response['scope']).to eq('granular')

      get_group(group, token_response['access_token'])
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'when the granular_oauth_tokens feature flag is disabled' do
    before do
      stub_feature_flags(granular_oauth_tokens: false)
    end

    it 'mints a legacy token and records no consent grant' do
      post '/oauth/authorize', params: authorization_params

      token_response = exchange_code(code_from(response.location))

      expect(token_response['scope']).to eq('api')
      expect(active_grant).to be_nil
    end
  end
end
