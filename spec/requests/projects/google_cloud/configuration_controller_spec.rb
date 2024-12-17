# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::ConfigurationController, feature_category: :deployment_management do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:url) { project_google_cloud_configuration_path(project) }

  let_it_be(:user_guest) { create(:user, guest_of: project) }
  let_it_be(:user_developer) { create(:user, developer_of: project) }
  let_it_be(:user_maintainer) { create(:user, maintainer_of: project) }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer] }

  context 'when accessed by unauthorized members' do
    it 'returns not found on GET request' do
      unauthorized_members.each do |unauthorized_member|
        sign_in(unauthorized_member)

        get url
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::ConfigurationController',
          action: 'error_invalid_user',
          label: nil,
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
        unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret).new('', '')
        allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                  .with('google_oauth2')
                                                  .and_return(unconfigured_google_oauth2)

        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          get url

          expect(response).to have_gitlab_http_status(:forbidden)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud::ConfigurationController',
            action: 'error_google_oauth2_not_enabled',
            label: nil,
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
            category: 'Projects::GoogleCloud::ConfigurationController',
            action: 'render_page',
            label: nil,
            project: project,
            user: authorized_member
          )
        end
      end
    end
  end
end
