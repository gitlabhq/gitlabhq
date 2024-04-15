# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::RevokeOauthController, feature_category: :deployment_management do
  include SessionHelpers

  describe 'POST #create', :snowplow, :clean_gitlab_redis_sessions, :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:url) { project_google_cloud_revoke_oauth_index_path(project).to_s }

    let(:user) { project.creator }

    before do
      sign_in(user)

      stub_session(session_data: { GoogleApi::CloudPlatform::Client.session_key_for_token => 'token' })

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    context 'when GCP token is invalid' do
      before do
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          allow(client).to receive(:validate_token).and_return(false)
        end
      end

      it 'redirects to Google OAuth2 authorize URL' do
        sign_in(user)

        post url

        expect(response).to redirect_to(assigns(:authorize_url))
      end
    end

    context 'when revocation is successful' do
      before do
        stub_request(:post, "https://oauth2.googleapis.com/revoke")
          .to_return(status: 200, body: "", headers: {})
      end

      it 'calls revoke endpoint and redirects' do
        post url

        expect(request.session[GoogleApi::CloudPlatform::Client.session_key_for_token]).to be_nil
        expect(response).to redirect_to(project_google_cloud_configuration_path(project))
        expect(flash[:notice]).to eq('Google OAuth2 token revocation requested')
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::RevokeOauthController',
          action: 'revoke_oauth',
          label: nil,
          project: project,
          user: user
        )
      end
    end

    context 'when revocation fails' do
      before do
        stub_request(:post, "https://oauth2.googleapis.com/revoke")
          .to_return(status: 400, body: "", headers: {})
      end

      it 'calls revoke endpoint and redirects' do
        post url

        expect(request.session[GoogleApi::CloudPlatform::Client.session_key_for_token]).to be_nil
        expect(response).to redirect_to(project_google_cloud_configuration_path(project))
        expect(flash[:alert]).to eq('Google OAuth2 token revocation request failed')
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::RevokeOauthController',
          action: 'error',
          label: nil,
          project: project,
          user: user
        )
      end
    end
  end
end
