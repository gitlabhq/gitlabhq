# frozen_string_literal: true

# Shared examples for the group- and project-scoped backend-for-frontend (BFF)
# session controllers (Groups::Observability::SessionsController and
# Projects::Observability::SessionsController), which both include the
# Observability::SessionActions concern and therefore share this behavior.
#
# The including spec must define:
#   - `make_request` (subject) - performs the POST to the controller action
#   - `user` - the signed-in user
#
# The including spec must already have called `sign_in(user)` and
# `stub_feature_flags(observability_sass_features: group, observability_per_user_bff_auth: group)`
# in its own `before` block before including these examples.
RSpec.shared_examples 'observability BFF session actions' do
  context 'when the broker returns tokens' do
    before do
      allow(::Observability::O11yBffSession).to receive(:generate_tokens)
        .and_return({ accessJwt: 'a-jwt', refreshJwt: 'r-jwt' })
    end

    it 'returns the per-user tokens as JSON' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(Gitlab::Json::SafeParser.parse(response.body)).to eq(
        'auth_tokens' => { 'access_jwt' => 'a-jwt', 'refresh_jwt' => 'r-jwt' }
      )
    end
  end

  context 'when the broker returns no tokens' do
    before do
      allow(::Observability::O11yBffSession).to receive(:generate_tokens).and_return({})
    end

    it 'returns 401' do
      make_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  context 'when the BFF feature flag is disabled' do
    before do
      stub_feature_flags(observability_per_user_bff_auth: false)
    end

    it 'returns 404' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when the observability_sass_features flag is disabled' do
    before do
      stub_feature_flags(observability_sass_features: false)
    end

    it 'returns 404' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when the rate limit is exceeded' do
    before do
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled_request?)
        .with(instance_of(ActionDispatch::Request), user, :observability_bff_session, scope: user)
        .and_return(true)
    end

    it 'returns 429' do
      make_request

      expect(response).to have_gitlab_http_status(:too_many_requests)
    end
  end

  context 'when the user is not authenticated' do
    before do
      sign_out(user)
    end

    it 'redirects to sign in' do
      make_request

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
