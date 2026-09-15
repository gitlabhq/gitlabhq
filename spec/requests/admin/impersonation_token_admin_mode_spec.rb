# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an impersonation token while admin mode is inactive', feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:admin) { create(:admin, organizations: [organization]) }
  let_it_be(:user) { create(:user, organizations: [organization]) }

  # rails-ujs defaults `data-type` to "script", so the remote token form sends this Accept
  # header. `xhr: true` on its own substitutes a test-only default that the application
  # never receives, which would stop this spec from pinning the production behaviour.
  let(:ujs_headers) do
    { 'ACCEPT' => 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript' }
  end

  let(:create_path) { admin_user_impersonation_tokens_path(user_id: user.username) }
  let(:token_params) do
    { personal_access_token: { name: 'test-token', scopes: ['api'], expires_at: 30.days.from_now.to_date.to_s } }
  end

  before do
    stub_application_setting(admin_mode: true)
    stub_config_setting(impersonation_enabled: true)

    sign_in(admin)

    # Enter admin mode for real, i.e. request it and then re-authenticate. The
    # `:enable_admin_mode` tag stubs `admin_mode?`, so it can never expire.
    get new_admin_session_path
    post admin_session_path, params: { user: { password: admin.password } }
  end

  shared_examples 'rejecting the request' do
    it 'answers with a JSON error and creates no token', :aggregate_failures do
      expect { post create_path, params: token_params, headers: ujs_headers, xhr: true }
        .not_to change { PersonalAccessToken.count }

      expect(response).to have_gitlab_http_status(:unauthorized)
      expect(response.media_type).to eq('application/json')
      expect(json_response['message']).to eq('Admin mode is inactive. Please re-authenticate.')
    end
  end

  it 'returns the token as JSON while admin mode is active', :aggregate_failures do
    post create_path, params: token_params, headers: ujs_headers, xhr: true

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/json')
    expect(json_response['new_token']).to be_present
  end

  context 'when the admin mode timeout has passed' do
    before do
      travel_to(Gitlab::Auth::CurrentUserMode::MAX_ADMIN_MODE_TIME.from_now + 1.second)
    end

    it_behaves_like 'rejecting the request'
  end

  context 'when admin mode was left explicitly rather than timing out' do
    before do
      post destroy_admin_session_path
    end

    it_behaves_like 'rejecting the request'
  end

  # Rotation is a PUT with no GET route, so storing its path would send the admin to a 404
  # after re-authenticating.
  context 'when rotating a token after the admin mode timeout has passed' do
    let_it_be(:token) do
      create(:personal_access_token, :impersonation, user: user, organization: organization)
    end

    let(:rotate_path) { rotate_admin_user_impersonation_token_path(user_id: user.username, id: token.id) }

    it 'does not send the admin to the rejected path after re-authenticating', :aggregate_failures do
      travel_to(Gitlab::Auth::CurrentUserMode::MAX_ADMIN_MODE_TIME.from_now + 1.second) do
        put rotate_path, xhr: true

        expect(response).to have_gitlab_http_status(:unauthorized)

        get new_admin_session_path
        post admin_session_path, params: { user: { password: admin.password } }

        expect(response).to redirect_to(admin_root_path)
      end
    end
  end
end
