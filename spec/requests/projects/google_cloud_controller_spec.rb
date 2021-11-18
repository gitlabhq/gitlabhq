# frozen_string_literal: true

require 'spec_helper'

# Mock Types
MockGoogleOAuth2Credentials = Struct.new(:app_id, :app_secret)

RSpec.describe Projects::GoogleCloudController do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET index' do
    let_it_be(:url) { "#{project_google_cloud_index_path(project)}" }

    context 'when a public request is made' do
      it 'returns not found' do
        get url

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when a project.guest makes request' do
      let(:user) { create(:user) }

      it 'returns not found' do
        project.add_guest(user)
        sign_in(user)

        get url

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when project.developer makes request' do
      let(:user) { create(:user) }

      it 'returns not found' do
        project.add_developer(user)
        sign_in(user)

        get url

        expect(response).to have_gitlab_http_status(:not_found)
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
        before do
          unconfigured_google_oauth2 = MockGoogleOAuth2Credentials.new('', '')
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)
        end

        it 'returns forbidden' do
          sign_in(user)

          get url

          expect(response).to have_gitlab_http_status(:forbidden)
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
        end
      end
    end
  end
end
