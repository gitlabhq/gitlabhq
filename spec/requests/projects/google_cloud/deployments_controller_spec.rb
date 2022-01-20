# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DeploymentsController do
  let_it_be(:project) { create(:project, :public) }

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
            sign_in(unauthorized_member)

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
