# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DeploymentsController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:repository) { project.repository }

  let_it_be(:user_guest) { create(:user) }
  let_it_be(:user_developer) { create(:user) }
  let_it_be(:user_maintainer) { create(:user) }
  let_it_be(:user_creator) { project.creator }

  let_it_be(:unauthorized_members) { [user_guest, user_developer] }
  let_it_be(:authorized_members) { [user_maintainer, user_creator] }

  let_it_be(:urls_list) { %W[#{project_google_cloud_deployments_cloud_run_path(project)} #{project_google_cloud_deployments_cloud_storage_path(project)}] }

  before do
    project.add_guest(user_guest)
    project.add_developer(user_developer)
    project.add_maintainer(user_maintainer)
  end

  describe "Routes must be restricted behind Google OAuth2" do
    context 'when a public request is made' do
      it 'returns not found on GET request' do
        urls_list.each do |url|
          get url

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when unauthorized members make requests' do
      it 'returns not found on GET request' do
        urls_list.each do |url|
          unauthorized_members.each do |unauthorized_member|
            get url

            expect(response).to have_gitlab_http_status(:not_found)
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

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_run' do
    let_it_be(:url) { "#{project_google_cloud_deployments_cloud_run_path(project)}" }

    before do
      sign_in(user_maintainer)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
        allow(client).to receive(:validate_token).and_return(true)
      end
    end

    it 'redirects to google_cloud home on enable service error' do
      # since GPC_PROJECT_ID is not set, enable cloud run service should return an error

      get url

      expect(response).to redirect_to(project_google_cloud_index_path(project))
    end

    it 'tracks error and redirects to gcp_error' do
      mock_google_error = Google::Apis::ClientError.new('some_error')

      allow_next_instance_of(GoogleCloud::EnableCloudRunService) do |service|
        allow(service).to receive(:execute).and_raise(mock_google_error)
      end

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(mock_google_error, { project_id: project.id })

      get url

      expect(response).to render_template(:gcp_error)
    end

    context 'GCP_PROJECT_IDs are defined' do
      it 'redirects to google_cloud home on generate pipeline error' do
        allow_next_instance_of(GoogleCloud::EnableCloudRunService) do |enable_cloud_run_service|
          allow(enable_cloud_run_service).to receive(:execute).and_return({ status: :success })
        end

        allow_next_instance_of(GoogleCloud::GeneratePipelineService) do |generate_pipeline_service|
          allow(generate_pipeline_service).to receive(:execute).and_return({ status: :error })
        end

        get url

        expect(response).to redirect_to(project_google_cloud_index_path(project))
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
      end
    end
  end

  describe 'Authorized GET project/-/google_cloud/deployments/cloud_storage' do
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
