# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DeploymentsController, feature_category: :deployment_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:repository) { project.repository }

  let_it_be(:user_guest) { create(:user, guest_of: project) }
  let_it_be(:user_developer) { create(:user, developer_of: project) }
  let_it_be(:user_maintainer) { create(:user, maintainer_of: project) }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer] }

  let_it_be(:urls_list) { %W[#{project_google_cloud_deployments_cloud_run_path(project)} #{project_google_cloud_deployments_cloud_storage_path(project)}] }

  describe "Routes must be restricted behind Google OAuth2", :snowplow do
    context 'when a public request is made' do
      it 'returns not found on GET request' do
        urls_list.each do |url|
          get url

          expect(response).to have_gitlab_http_status(:not_found)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud::DeploymentsController',
            action: 'error_invalid_user',
            label: nil,
            project: project,
            user: nil
          )
        end
      end
    end

    context 'when unauthorized members make requests' do
      it 'returns not found on GET request' do
        urls_list.each do |url|
          unauthorized_members.each do |unauthorized_member|
            get url

            expect(response).to have_gitlab_http_status(:not_found)
            expect_snowplow_event(
              category: 'Projects::GoogleCloud::DeploymentsController',
              action: 'error_invalid_user',
              label: nil,
              project: project,
              user: nil
            )
          end
        end
      end
    end

    context 'when authorized members make requests' do
      it 'redirects on GET request' do
        urls_list.each do |url|
          authorized_members.each do |authorized_member|
            sign_in(authorized_member)

            get url

            expect(response).to redirect_to(assigns(:authorize_url))
          end
        end
      end
    end
  end

  describe 'Authorized GET project/-/google_cloud/deployments', :snowplow do
    before do
      sign_in(user_maintainer)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    it 'renders template' do
      get project_google_cloud_deployments_path(project).to_s

      expect(response).to render_template(:index)

      expect_snowplow_event(
        category: 'Projects::GoogleCloud::DeploymentsController',
        action: 'render_page',
        label: nil,
        project: project,
        user: user_maintainer
      )
    end
  end

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_run', :snowplow do
    let_it_be(:url) { project_google_cloud_deployments_cloud_run_path(project).to_s }

    before do
      sign_in(user_maintainer)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    context 'when enable service fails' do
      before do
        allow_next_instance_of(CloudSeed::GoogleCloud::EnableCloudRunService) do |service|
          allow(service)
            .to receive(:execute)
            .and_return(
              status: :error,
              message: 'No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable'
            )
        end
      end

      it 'redirects to google cloud deployments and tracks event on enable service error' do
        get url

        expect(response).to redirect_to(project_google_cloud_deployments_path(project))
        # since GPC_PROJECT_ID is not set, enable cloud run service should return an error
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::DeploymentsController',
          action: 'error_enable_services',
          label: nil,
          project: project,
          user: user_maintainer
        )
      end

      it 'shows a flash alert' do
        get url

        expect(flash[:alert])
          .to eq('No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable')
      end
    end

    context 'when enable service raises an error' do
      before do
        mock_gcp_error = Google::Apis::ClientError.new('some_error')

        allow_next_instance_of(CloudSeed::GoogleCloud::EnableCloudRunService) do |service|
          allow(service).to receive(:execute).and_raise(mock_gcp_error)
        end
      end

      it 'redirects to google cloud deployments with error' do
        get url

        expect(response).to redirect_to(project_google_cloud_deployments_path(project))
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::DeploymentsController',
          action: 'error_google_api',
          label: nil,
          project: project,
          user: user_maintainer
        )
      end

      it 'shows a flash warning' do
        get url

        expect(flash[:warning]).to eq(format(_('Google Cloud Error - %{error}'), error: 'some_error'))
      end
    end

    context 'GCP_PROJECT_IDs are defined' do
      before do
        allow_next_instance_of(CloudSeed::GoogleCloud::EnableCloudRunService) do |enable_cloud_run_service|
          allow(enable_cloud_run_service).to receive(:execute).and_return({ status: :success })
        end
      end

      context 'when generate pipeline service fails' do
        before do
          allow_next_instance_of(CloudSeed::GoogleCloud::GeneratePipelineService) do |generate_pipeline_service|
            allow(generate_pipeline_service).to receive(:execute).and_return({ status: :error })
          end
        end

        it 'redirects to google_cloud deployments and tracks event on generate pipeline error' do
          get url

          expect(response).to redirect_to(project_google_cloud_deployments_path(project))
          expect_snowplow_event(
            category: 'Projects::GoogleCloud::DeploymentsController',
            action: 'error_generate_cloudrun_pipeline',
            label: nil,
            project: project,
            user: user_maintainer
          )
        end

        it 'shows a flash alert' do
          get url

          expect(flash[:alert]).to eq('Failed to generate pipeline')
        end
      end

      it 'redirects to create merge request form' do
        allow_next_instance_of(CloudSeed::GoogleCloud::GeneratePipelineService) do |service|
          allow(service).to receive(:execute).and_return({ status: :success })
        end

        get url

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to include(project_new_merge_request_path(project))
        expect_snowplow_event(
          category: 'Projects::GoogleCloud::DeploymentsController',
          action: 'generate_cloudrun_pipeline',
          label: nil,
          project: project,
          user: user_maintainer
        )
      end
    end
  end

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_storage', :snowplow do
    let_it_be(:url) { project_google_cloud_deployments_cloud_storage_path(project).to_s }

    before do
      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    it 'renders placeholder' do
      authorized_members.each do |authorized_member|
        sign_in(authorized_member)

        get url

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
