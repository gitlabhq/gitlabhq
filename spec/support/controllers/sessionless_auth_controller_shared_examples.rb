# frozen_string_literal: true

shared_examples 'authenticates sessionless user' do |path, format, params|
  params ||= {}

  before do
    stub_authentication_activity_metrics(debug: false)
  end

  let(:user) { create(:user) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:default_params) { { format: format }.merge(params.except(:public) || {}) }

  context "when the 'personal_access_token' param is populated with the personal access token" do
    it 'logs the user in' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)
                     .and increment(:user_sessionless_authentication_counter)

      get path, params: default_params.merge(private_token: personal_access_token.token)

      expect(response).to have_gitlab_http_status(200)
      expect(controller.current_user).to eq(user)
    end

    it 'does not log the user in if page is public', if: params[:public] do
      get path, params: default_params

      expect(response).to have_gitlab_http_status(200)
      expect(controller.current_user).to be_nil
    end
  end

  context 'when the personal access token has no api scope', unless: params[:public] do
    it 'does not log the user in' do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)

      personal_access_token.update(scopes: [:read_user])

      get path, params: default_params.merge(private_token: personal_access_token.token)

      expect(response).not_to have_gitlab_http_status(200)
    end
  end

  context "when the 'PERSONAL_ACCESS_TOKEN' header is populated with the personal access token" do
    it 'logs the user in' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)
                     .and increment(:user_sessionless_authentication_counter)

      @request.headers['PRIVATE-TOKEN'] = personal_access_token.token
      get path, params: default_params

      expect(response).to have_gitlab_http_status(200)
    end
  end

  context "when the 'feed_token' param is populated with the feed token", if: format == :rss do
    it "logs the user in" do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
              .and increment(:user_session_override_counter)
                     .and increment(:user_sessionless_authentication_counter)

      get path, params: default_params.merge(feed_token: user.feed_token)

      expect(response).to have_gitlab_http_status 200
    end
  end

  context "when the 'feed_token' param is populated with an invalid feed token", if: format == :rss, unless: params[:public] do
    it "logs the user" do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)

      get path, params: default_params.merge(feed_token: 'token')

      expect(response.status).not_to eq 200
    end
  end

  it "doesn't log the user in otherwise", unless: params[:public] do
    expect(authentication_metrics)
      .to increment(:user_unauthenticated_counter)

    get path, params: default_params.merge(private_token: 'token')

    expect(response.status).not_to eq(200)
  end
end
