# frozen_string_literal: true

require 'spec_helper'

# Mock Types
MockGoogleOAuth2Credentials = Struct.new(:app_id, :app_secret)

RSpec.describe Projects::GoogleCloudController do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET index', :snowplow do
    let_it_be(:url) { "#{project_google_cloud_index_path(project)}" }

    context 'when a public request is made' do
      it 'returns not found' do
        get url

        expect(response).to have_gitlab_http_status(:not_found)
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'admin_project_google_cloud!',
          label: 'access_denied',
          property: 'invalid_user',
          project: project,
          user: nil)
      end
    end

    context 'when a project.guest makes request' do
      let(:user) { create(:user) }

      it 'returns not found' do
        project.add_guest(user)
        sign_in(user)

        get url

        expect(response).to have_gitlab_http_status(:not_found)
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'admin_project_google_cloud!',
          label: 'access_denied',
          property: 'invalid_user',
          project: project,
          user: user
        )
      end
    end

    context 'when project.developer makes request' do
      let(:user) { create(:user) }

      it 'returns not found' do
        project.add_developer(user)
        sign_in(user)

        get url

        expect(response).to have_gitlab_http_status(:not_found)
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'admin_project_google_cloud!',
          label: 'access_denied',
          property: 'invalid_user',
          project: project,
          user: user
        )
      end
    end

    context 'when project.maintainer makes request' do
      let(:user) { create(:user) }

      it 'returns successful' do
        project.add_maintainer(user)
        sign_in(user)

        get url

        expect(response).to be_successful
      end
    end

    context 'when project.creator makes request' do
      let(:user) { project.creator }

      it 'returns successful' do
        sign_in(user)

        get url

        expect(response).to be_successful
      end
    end

    describe 'when authorized user makes request' do
      let(:user) { project.creator }

      context 'but gitlab instance is not configured for google oauth2' do
        it 'returns forbidden' do
          unconfigured_google_oauth2 = MockGoogleOAuth2Credentials.new('', '')
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)

          sign_in(user)

          get url

          expect(response).to have_gitlab_http_status(:forbidden)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'google_oauth2_enabled!',
            label: 'access_denied',
            extra: { reason: 'google_oauth2_not_configured',
                     config: unconfigured_google_oauth2 },
            project: project,
            user: user
          )
        end
      end

      context 'but feature flag is disabled' do
        before do
          stub_feature_flags(incubation_5mp_google_cloud: false)
        end

        it 'returns not found' do
          sign_in(user)

          get url

          expect(response).to have_gitlab_http_status(:not_found)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'feature_flag_enabled!',
            label: 'access_denied',
            property: 'feature_flag_not_enabled',
            project: project,
            user: user
          )
        end
      end
    end
  end
end
