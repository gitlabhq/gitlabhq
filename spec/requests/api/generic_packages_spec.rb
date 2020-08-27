# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GenericPackages do
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:project) { create(:project) }

  describe 'GET /api/v4/projects/:id/packages/generic/ping' do
    let(:user) { personal_access_token.user }
    let(:auth_token) { personal_access_token.token }

    before do
      project.add_developer(user)
    end

    context 'packages feature is disabled' do
      it 'responds with 404 Not Found' do
        stub_packages_setting(enabled: false)

        ping(personal_access_token: auth_token)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'generic_packages feature flag is disabled' do
      it 'responds with 404 Not Found' do
        stub_feature_flags(generic_packages: false)

        ping(personal_access_token: auth_token)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'generic_packages feature flag is enabled' do
      before do
        stub_feature_flags(generic_packages: true)
      end

      context 'authenticating using personal access token' do
        it 'responds with 200 OK when valid personal access token is provided' do
          ping(personal_access_token: auth_token)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'responds with 401 Unauthorized when invalid personal access token provided' do
          ping(personal_access_token: 'invalid-token')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'authenticating using job token' do
        it 'responds with 200 OK when valid job token is provided' do
          job_token = create(:ci_build, user: user).token

          ping(job_token: job_token)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'responds with 401 Unauthorized when invalid job token provided' do
          ping(job_token: 'invalid-token')

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    def ping(personal_access_token: nil, job_token: nil)
      headers = {
        Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => personal_access_token.presence,
        Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => job_token.presence
      }.compact

      get api('/projects/%d/packages/generic/ping' % project.id), headers: headers
    end
  end
end
