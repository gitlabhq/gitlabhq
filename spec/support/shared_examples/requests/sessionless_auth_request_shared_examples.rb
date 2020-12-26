# frozen_string_literal: true

RSpec.shared_examples 'authenticates sessionless user for the request spec' do |params|
  params ||= {}

  before do
    stub_authentication_activity_metrics(debug: false)
  end

  let(:user) { create(:user) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:default_params) { params.except(:public) || {} }

  context "when the 'personal_access_token' param is populated with the personal access token" do
    it 'logs the user in' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)
                     .and increment(:user_sessionless_authentication_counter)

      get url, params: default_params.merge(private_token: personal_access_token.token)

      expect(response).to have_gitlab_http_status(:ok)
      expect(controller.current_user).to eq(user)
    end

    it 'does not log the user in if page is public', if: params[:public] do
      get url, params: default_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(controller.current_user).to be_nil
    end
  end

  context 'when the personal access token has no api scope', unless: params[:public] do
    it 'does not log the user in' do
      # Several instances of where these specs are shared route the request
      #   through ApplicationController#route_not_found which does not involve
      #   the usual auth code from Devise, so does not increment the
      #   :user_unauthenticated_counter
      #
      unless params[:ignore_incrementing]
        expect(authentication_metrics)
          .to increment(:user_unauthenticated_counter)
      end

      personal_access_token.update!(scopes: [:read_user])

      get url, params: default_params.merge(private_token: personal_access_token.token)

      expect(response).not_to have_gitlab_http_status(:ok)
    end
  end

  context "when the 'PERSONAL_ACCESS_TOKEN' header is populated with the personal access token" do
    it 'logs the user in' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)
                     .and increment(:user_sessionless_authentication_counter)

      headers = { 'PRIVATE-TOKEN': personal_access_token.token }
      get url, params: default_params, headers: headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  it "doesn't log the user in otherwise", unless: params[:public] do
    # Several instances of where these specs are shared route the request
    #   through ApplicationController#route_not_found which does not involve
    #   the usual auth code from Devise, so does not increment the
    #   :user_unauthenticated_counter
    #
    unless params[:ignore_incrementing]
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
    end

    get url, params: default_params.merge(private_token: 'token')

    expect(response).not_to have_gitlab_http_status(:ok)
  end
end
