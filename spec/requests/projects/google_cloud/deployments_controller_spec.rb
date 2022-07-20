# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DeploymentsController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:repository) { project.repository }

  let_it_be(:user_guest) { create(:user) }
  let_it_be(:user_developer) { create(:user) }
  let_it_be(:user_maintainer) { create(:user) }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer] }

  let_it_be(:urls_list) { %W[#{project_google_cloud_deployments_cloud_run_path(project)} #{project_google_cloud_deployments_cloud_storage_path(project)}] }

  before do
    project.add_guest(user_guest)
    project.add_developer(user_developer)
    project.add_maintainer(user_maintainer)
  end

  describe "Routes must be restricted behind Google OAuth2", :snowplow do
    context 'when a public request is made' do
      it 'returns not found on GET request' do
        urls_list.each do |url|
          get url

          expect(response).to have_gitlab_http_status(:not_found)
          expect_snowplow_event(
            category: 'Projects::GoogleCloud',
            action: 'admin_project_google_cloud!',
            label: 'error_access_denied',
            property: 'invalid_user',
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
              category: 'Projects::GoogleCloud',
              action: 'admin_project_google_cloud!',
              label: 'error_access_denied',
              property: 'invalid_user',
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

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_run', :snowplow do
    let_it_be(:url) { "#{project_google_cloud_deployments_cloud_run_path(project)}" }

    before do
      sign_in(user_maintainer)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    it 'redirects to google cloud deployments on enable service error' do
      get url

      expect(response).to redirect_to(project_google_cloud_deployments_path(project))
      # since GPC_PROJECT_ID is not set, enable cloud run service should return an error
      expect_snowplow_event(
        category: 'Projects::GoogleCloud',
        action: 'deployments#cloud_run',
        label: 'error_enable_cloud_run',
        extra: { message: 'No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable.',
                 status: :error },
        project: project,
        user: user_maintainer
      )
    end

    it 'redirects to google cloud deployments with error' do
      mock_gcp_error = Google::Apis::ClientError.new('some_error')

      allow_next_instance_of(GoogleCloud::EnableCloudRunService) do |service|
        allow(service).to receive(:execute).and_raise(mock_gcp_error)
      end

      get url

      expect(response).to redirect_to(project_google_cloud_deployments_path(project))
      expect_snowplow_event(
        category: 'Projects::GoogleCloud',
        action: 'deployments#cloud_run',
        label: 'error_gcp',
        extra: mock_gcp_error,
        project: project,
        user: user_maintainer
      )
    end

    context 'GCP_PROJECT_IDs are defined' do
      it 'redirects to google_cloud deployments on generate pipeline error' do
        allow_next_instance_of(GoogleCloud::EnableCloudRunService) do |enable_cloud_run_service|
          allow(enable_cloud_run_service).to receive(:execute).and_return({ status: :success })
        end

        allow_next_instance_of(GoogleCloud::GeneratePipelineService) do |generate_pipeline_service|
          allow(generate_pipeline_service).to receive(:execute).and_return({ status: :error })
        end

        get url

        expect(response).to redirect_to(project_google_cloud_deployments_path(project))
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'deployments#cloud_run',
          label: 'error_generate_pipeline',
          extra: { status: :error },
          project: project,
          user: user_maintainer
        )
      end

      it 'redirects to create merge request form' do
        allow_next_instance_of(GoogleCloud::EnableCloudRunService) do |service|
          allow(service).to receive(:execute).and_return({ status: :success })
        end

        allow_next_instance_of(GoogleCloud::GeneratePipelineService) do |service|
          allow(service).to receive(:execute).and_return({ status: :success })
        end

        get url

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to include(project_new_merge_request_path(project))
        expect_snowplow_event(
          category: 'Projects::GoogleCloud',
          action: 'deployments#cloud_run',
          label: 'success',
          extra: { "title": "Enable deployments to Cloud Run",
                   "description": "This merge request includes a Cloud Run deployment job in the pipeline definition (.gitlab-ci.yml).\n\nThe `deploy-to-cloud-run` job:\n* Requires the following environment variables\n    * `GCP_PROJECT_ID`\n    * `GCP_SERVICE_ACCOUNT_KEY`\n* Job definition can be found at: https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library\n\nThis pipeline definition has been committed to the branch ``.\nYou may modify the pipeline definition further or accept the changes as-is if suitable.\n",
                   "source_project_id": project.id,
                   "target_project_id": project.id,
                   "source_branch": nil,
                   "target_branch": project.default_branch },
          project: project,
          user: user_maintainer
        )
      end
    end
  end

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_storage', :snowplow do
    let_it_be(:url) { "#{project_google_cloud_deployments_cloud_storage_path(project)}" }

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
