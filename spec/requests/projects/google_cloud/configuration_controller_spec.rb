# frozen_string_literal: true

require 'spec_helper'

# Mock Types
MockGoogleOAuth2Credentials = Struct.new(:app_id, :app_secret)

RSpec.describe Projects::GoogleCloud::ConfigurationController do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:url) { project_google_cloud_configuration_path(project) }

  let_it_be(:user_guest) { create(:user) }
  let_it_be(:user_developer) { create(:user) }
  let_it_be(:user_maintainer) { create(:user) }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer] }

  before do
    project.add_guest(user_guest)
    project.add_developer(user_developer)
    project.add_maintainer(user_maintainer)
  end

  context 'when accessed by unauthorized members' do
    it 'returns not found on GET request' do
      unauthorized_members.each do |unauthorized_member|
        sign_in(unauthorized_member)

        get url
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'admin_project_google_cloud!',
          label: 'error_access_denied',
          property: 'invalid_user',
          project: project,
          user: unauthorized_member
        )

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when accessed by authorized members' do
    it 'returns successful' do
      authorized_members.each do |authorized_member|
        sign_in(authorized_member)

        get url

        expect(response).to be_successful
        expect(response).to render_template('projects/google_cloud/configuration/index')
      end
    end

    context 'but gitlab instance is not configured for google oauth2' do
      it 'returns forbidden' do
        unconfigured_google_oauth2 = MockGoogleOAuth2Credentials.new('', '')
        allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                  .with('google_oauth2')
                                                  .and_return(unconfigured_google_oauth2)

        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          get url

          expect(response).to have_gitlab_http_status(:forbidden)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'google_oauth2_enabled!',
            label: 'error_access_denied',
            extra: { reason: 'google_oauth2_not_configured',
                     config: unconfigured_google_oauth2 },
            project: project,
            user: authorized_member
          )
        end
      end
    end

    context 'but feature flag is disabled' do
      before do
        stub_feature_flags(incubation_5mp_google_cloud: false)
      end

      it 'returns not found' do
        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          get url

          expect(response).to have_gitlab_http_status(:not_found)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'feature_flag_enabled!',
            label: 'error_access_denied',
            property: 'feature_flag_not_enabled',
            project: project,
            user: authorized_member
          )
        end
      end
    end

    context 'but google oauth2 token is not valid' do
      it 'does not return revoke oauth url' do
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          allow(client).to receive(:validate_token).and_return(false)
        end

        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          get url

          expect(response).to be_successful
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'configuration#index',
            label: 'success',
            extra: {
              configurationUrl: project_google_cloud_configuration_path(project),
              deploymentsUrl: project_google_cloud_deployments_path(project),
              databasesUrl: project_google_cloud_databases_path(project),
              serviceAccounts: [],
              createServiceAccountUrl: project_google_cloud_service_accounts_path(project),
              emptyIllustrationUrl: ActionController::Base.helpers.image_path('illustrations/pipelines_empty.svg'),
              configureGcpRegionsUrl: project_google_cloud_gcp_regions_path(project),
              gcpRegions: [],
              revokeOauthUrl: nil
            },
            project: project,
            user: authorized_member
          )
        end
      end
    end
  end
end
