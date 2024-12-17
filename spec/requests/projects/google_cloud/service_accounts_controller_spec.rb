# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::ServiceAccountsController, feature_category: :deployment_management do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET index', :snowplow do
    let_it_be(:url) { project_google_cloud_service_accounts_path(project).to_s }

    let_it_be(:user_guest) { create(:user) }
    let_it_be(:user_developer) { create(:user) }
    let_it_be(:user_maintainer) { create(:user) }
    let_it_be(:user_creator) { project.creator }

    let_it_be(:unauthorized_members) { [user_guest, user_developer] }
    let_it_be(:authorized_members) { [user_maintainer, user_creator] }

    let_it_be(:google_client_error) { Google::Apis::ClientError.new('client-error') }

    before do
      project.add_guest(user_guest)
      project.add_developer(user_developer)
      project.add_maintainer(user_maintainer)
    end

    context 'when a public request is made' do
      it 'returns not found on GET request' do
        get url

        expect(response).to have_gitlab_http_status(:not_found)
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::ServiceAccountsController',
          action: 'error_invalid_user',
          label: nil,
          project: project,
          user: nil
        )
      end

      it 'returns not found on POST request' do
        post url

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthorized members make requests' do
      it 'returns not found on GET request' do
        unauthorized_members.each do |unauthorized_member|
          sign_in(unauthorized_member)

          get url
          expect_snowplow_event(
            category: 'Projects::GoogleCloud::ServiceAccountsController',
            action: 'error_invalid_user',
            label: nil,
            project: project,
            user: unauthorized_member
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'returns not found on POST request' do
        unauthorized_members.each do |unauthorized_member|
          sign_in(unauthorized_member)

          post url
          expect_snowplow_event(
            category: 'Projects::GoogleCloud::ServiceAccountsController',
            action: 'error_invalid_user',
            label: nil,
            project: project,
            user: unauthorized_member
          )

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when authorized members make requests' do
      it 'redirects on GET request' do
        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          get url

          expect(response).to redirect_to(assigns(:authorize_url))
        end
      end

      it 'redirects on POST request' do
        authorized_members.each do |authorized_member|
          sign_in(authorized_member)

          post url

          expect(response).to redirect_to(assigns(:authorize_url))
        end
      end

      context 'and user has successfully completed the google oauth2 flow' do
        context 'but the user does not have gcp projects' do
          before do
            allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
              mock_service_account = Struct.new(:project_id, :unique_id, :email).new(123, 456, 'em@ai.l')
              allow(client).to receive(:list_projects).and_return([])
              allow(client).to receive(:validate_token).and_return(true)
              allow(client).to receive(:create_service_account).and_return(mock_service_account)
              allow(client).to receive(:create_service_account_key).and_return({})
              allow(client).to receive(:grant_service_account_roles)
            end
          end

          it 'flashes error and redirects to google cloud configurations' do
            authorized_members.each do |authorized_member|
              allow_next_instance_of(BranchesFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              allow_next_instance_of(TagsFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              sign_in(authorized_member)

              get url

              expect(response).to redirect_to(project_google_cloud_configuration_path(project))
              expect(flash[:warning]).to eq('No Google Cloud projects - You need at least one Google Cloud project')
              expect_snowplow_event(
                category: 'Projects::GoogleCloud::ServiceAccountsController',
                action: 'error_no_gcp_projects',
                label: nil,
                project: project,
                user: authorized_member
              )
            end
          end
        end

        context 'user has three gcp_projects' do
          before do
            allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
              mock_service_account = Struct.new(:project_id, :unique_id, :email).new(123, 456, 'em@ai.l')
              allow(client).to receive(:list_projects).and_return([{}, {}, {}])
              allow(client).to receive(:validate_token).and_return(true)
              allow(client).to receive(:create_service_account).and_return(mock_service_account)
              allow(client).to receive(:create_service_account_key).and_return({})
              allow(client).to receive(:grant_service_account_roles)
            end
          end

          it 'returns success on GET' do
            authorized_members.each do |authorized_member|
              allow_next_instance_of(BranchesFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              allow_next_instance_of(TagsFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              sign_in(authorized_member)

              get url

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'returns success on POST' do
            authorized_members.each do |authorized_member|
              sign_in(authorized_member)

              post url, params: { gcp_project: 'prj1', ref: 'env1' }

              expect(response).to redirect_to(project_google_cloud_configuration_path(project))
            end
          end
        end
      end

      context 'but google returns client error' do
        before do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
            allow(client).to receive(:validate_token).and_return(true)
            allow(client).to receive(:list_projects).and_raise(google_client_error)
            allow(client).to receive(:create_service_account).and_raise(google_client_error)
            allow(client).to receive(:create_service_account_key).and_raise(google_client_error)
          end
        end

        it 'GET flashes error and redirects to -/google_cloud/configurations' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            get url

            expect(response).to redirect_to(project_google_cloud_configuration_path(project))
            expect(flash[:warning]).to eq('Google Cloud Error - client-error')
            expect_snowplow_event(
              category: 'Projects::GoogleCloud::ServiceAccountsController',
              action: 'error_google_api',
              project: project,
              label: nil,
              user: authorized_member
            )
          end
        end

        it 'POST flashes error and redirects to -/google_cloud/configurations' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            post url, params: { gcp_project: 'prj1', environment: 'env1' }

            expect(response).to redirect_to(project_google_cloud_configuration_path(project))
            expect(flash[:warning]).to eq('Google Cloud Error - client-error')
            expect_snowplow_event(
              category: 'Projects::GoogleCloud::ServiceAccountsController',
              action: 'error_google_api',
              label: nil,
              project: project,
              user: authorized_member
            )
          end
        end
      end

      context 'but gitlab instance is not configured for google oauth2' do
        before do
          unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret)
                                             .new('', '')
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)
        end

        it 'returns forbidden' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            get url

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end
end
