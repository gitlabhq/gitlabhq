# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::ServiceAccountsController do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET index', :snowplow do
    let_it_be(:url) { "#{project_google_cloud_service_accounts_path(project)}" }

    let(:user_guest) { create(:user) }
    let(:user_developer) { create(:user) }
    let(:user_maintainer) { create(:user) }
    let(:user_creator) { project.creator }

    let(:unauthorized_members) { [user_guest, user_developer] }
    let(:authorized_members) { [user_maintainer, user_creator] }

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
          category: 'Projects::GoogleCloud',
          action: 'admin_project_google_cloud!',
          label: 'access_denied',
          property: 'invalid_user',
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
            category: 'Projects::GoogleCloud',
            action: 'admin_project_google_cloud!',
            label: 'access_denied',
            property: 'invalid_user',
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
            category: 'Projects::GoogleCloud',
            action: 'admin_project_google_cloud!',
            label: 'access_denied',
            property: 'invalid_user',
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

          it 'renders no_gcp_projects' do
            authorized_members.each do |authorized_member|
              allow_next_instance_of(BranchesFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              allow_next_instance_of(TagsFinder) do |branches_finder|
                allow(branches_finder).to receive(:execute).and_return([])
              end

              sign_in(authorized_member)

              get url

              expect(response).to render_template('projects/google_cloud/errors/no_gcp_projects')
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

              expect(response).to redirect_to(project_google_cloud_index_path(project))
            end
          end
        end
      end

      context 'but google returns client error' do
        before do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
            allow(client).to receive(:validate_token).and_return(true)
            allow(client).to receive(:list_projects).and_raise(Google::Apis::ClientError.new(''))
            allow(client).to receive(:create_service_account).and_raise(Google::Apis::ClientError.new(''))
            allow(client).to receive(:create_service_account_key).and_raise(Google::Apis::ClientError.new(''))
          end
        end

        it 'renders gcp_error template on GET' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            get url

            expect(response).to render_template(:gcp_error)
          end
        end

        it 'renders gcp_error template on POST' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            post url, params: { gcp_project: 'prj1', environment: 'env1' }

            expect(response).to render_template(:gcp_error)
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

      context 'but feature flag is disabled' do
        before do
          stub_feature_flags(incubation_5mp_google_cloud: false)
        end

        it 'returns not found' do
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            get url

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
