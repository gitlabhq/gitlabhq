# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectServiceAccounts, :with_current_organization, :aggregate_failures,
  :clean_gitlab_redis_rate_limiting, feature_category: :user_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project) }

  before do
    stub_application_setting_enum('email_confirmation_setting', 'hard')
  end

  describe "POST /projects/:id/service_accounts" do
    let(:project_id) { project.id }
    let(:params) { {} }

    subject(:perform_request) { post api("/projects/#{project_id}/service_accounts", current_user), params: params }

    context 'when current user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it 'creates the user with default values' do
        perform_request

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['username']).to start_with('service_account_project_')
        expect(json_response.keys).to match_array(%w[id name username email public_email])
      end

      it 'sets provisioned_by_project on the service account user' do
        perform_request

        created = User.find(json_response['id'])
        expect(created.user_type).to eq('service_account')
        expect(created.provisioned_by_project_id).to eq(project_id)
        expect(created.namespace.organization).to eq(current_organization)
      end

      context 'when params are provided' do
        let(:params) do
          {
            name: 'John Doe',
            username: 'test',
            email: 'test_service_account@example.com'
          }
        end

        it 'creates the user with the provided details' do
          perform_request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['username']).to eq(params[:username])
          expect(json_response['name']).to eq(params[:name])
          expect(json_response['email']).to eq(params[:email])
        end

        context 'when user with the same username and email already exists' do
          before do
            post api("/projects/#{project_id}/service_accounts", current_user), params: params
          end

          it 'returns a bad_request error' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Username has already been taken')
            expect(json_response['message']).to include('Email has already been taken')
          end
        end
      end

      context 'when the project does not exist' do
        let(:project_id) { non_existing_record_id }

        it 'returns 404' do
          perform_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'returns a bad_request error when the service returns one' do
        allow_next_instance_of(::Namespaces::ServiceAccounts::ProjectCreateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'something went wrong', reason: :bad_request)
          )
        end

        perform_request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when current user is a non-maintainer project member' do
      let(:current_user) { create(:user, developer_of: project) }

      it 'returns 403' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without authentication' do
      it 'returns 401' do
        post api("/projects/#{project_id}/service_accounts"), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'for rate limiting' do
      let_it_be(:admin2) { create(:admin) }

      let(:current_user) { admin }

      def request
        post api("/projects/#{project.id}/service_accounts", admin, admin_mode: true), params: params
      end

      def request_with_second_scope
        post api("/projects/#{project.id}/service_accounts", admin2, admin_mode: true), params: params
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :service_account_creation
    end
  end

  describe "GET /projects/:id/service_accounts" do
    let(:project_id) { project.id }
    let(:path) { "/projects/#{project_id}/service_accounts" }
    let(:params) { {} }

    subject(:perform_request) { get api(path, current_user, admin_mode: true), params: params }

    context 'when the user is an admin', :enable_admin_mode do
      let(:current_user) { admin }
      let!(:service_account_a) do
        create(:user, :service_account, username: "auser_#{SecureRandom.hex(2)}", provisioned_by_project: project)
      end

      let!(:service_account_b) do
        create(:user, :service_account, username: "buser_#{SecureRandom.hex(2)}", provisioned_by_project: project)
      end

      let!(:regular_user) { create(:user, provisioned_by_project: project) }

      it 'returns the list of service accounts in the project' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck("id")).to match_array([service_account_a.id, service_account_b.id])
        expect(json_response.pluck("id")).not_to include(regular_user.id)
      end

      context 'when order_by username asc' do
        let(:params) { { order_by: 'username', sort: 'asc' } }

        it 'orders by username ascending' do
          perform_request

          ordered = [service_account_a, service_account_b].sort_by(&:username)
          expect(json_response.pluck("id")).to eq(ordered.map(&:id))
        end
      end
    end

    context 'when the project does not exist' do
      let(:project_id) { non_existing_record_id }
      let(:current_user) { admin }

      it 'returns 404' do
        perform_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not a project member' do
      let(:current_user) { create(:user) }

      it 'returns 404 for a private project' do
        perform_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "PATCH /projects/:id/service_accounts/:user_id" do
    let(:project_id) { project.id }
    let!(:service_account_user) { create(:user, :service_account, provisioned_by_project: project) }
    let(:params) { { name: 'Updated Name', username: "updated_#{SecureRandom.hex(4)}" } }
    let(:path) { "/projects/#{project_id}/service_accounts/#{service_account_user.id}" }

    subject(:perform_request) { patch api(path, current_user, admin_mode: true), params: params }

    context 'when current user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it 'updates the service account user' do
        perform_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(params[:name])
        expect(json_response['username']).to eq(params[:username])
      end

      it 'returns 404 for a non-existing user' do
        patch api("/projects/#{project_id}/service_accounts/#{non_existing_record_id}", current_user,
          admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 400 for an invalid user ID' do
        patch api("/projects/#{project_id}/service_accounts/ASDF", current_user, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the project does not exist' do
      let(:project_id) { non_existing_record_id }
      let(:current_user) { admin }

      it 'returns 404' do
        perform_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when current user is not a project maintainer' do
      let(:current_user) { create(:user, developer_of: project) }

      it 'returns 403' do
        patch api(path, current_user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /projects/:id/service_accounts/:user_id" do
    let(:project_id) { project.id }
    let!(:service_account_user) { create(:user, :service_account, provisioned_by_project: project) }
    let(:path) { "/projects/#{project_id}/service_accounts/#{service_account_user.id}" }

    context 'when current user is an admin' do
      it 'marks the user for deletion', :sidekiq_inline do
        perform_enqueued_jobs { delete api(path, admin, admin_mode: true) }

        expect(response).to have_gitlab_http_status(:no_content)
        expect(Users::GhostUserMigration.where(user: service_account_user, initiator_user: admin)).to exist
      end

      it 'returns 404 for non-existing user' do
        perform_enqueued_jobs do
          delete api("/projects/#{project_id}/service_accounts/#{non_existing_record_id}", admin, admin_mode: true)
        end

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end
    end

    context 'when not authenticated' do
      it 'returns 401' do
        perform_enqueued_jobs { delete api(path) }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  # The PAT sub-routes require admin or self ability on the target user in CE
  # (see app/policies/user_policy.rb, app/policies/personal_access_token_policy.rb).
  # Project-maintainer-on-SA is gated by EE (ee/app/services/ee/personal_access_tokens/create_service.rb),
  # which is covered in the EE spec.
  describe "personal access token sub-routes (admin path)", :enable_admin_mode do
    let_it_be(:service_account_user) { create(:user, :service_account, provisioned_by_project: project) }

    let(:base_path) do
      "/projects/#{project.id}/service_accounts/#{service_account_user.id}/personal_access_tokens"
    end

    let_it_be(:scopes) { %w[api read_repository] }

    describe 'POST /projects/:id/service_accounts/:user_id/personal_access_tokens' do
      let(:params) do
        { name: 'pat-1', scopes: scopes, expires_at: 30.days.from_now.to_date.to_s }
      end

      it 'creates a token for the service account' do
        post api(base_path, admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('pat-1')
        expect(json_response['token']).to be_present
        expect(json_response['scopes']).to match_array(scopes)
      end

      it 'returns 404 when service account does not belong to the project' do
        other_sa = create(:user, :service_account)

        post api("/projects/#{project.id}/service_accounts/#{other_sa.id}/personal_access_tokens", admin,
          admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 401 without authentication' do
        post api(base_path), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    describe 'GET /projects/:id/service_accounts/:user_id/personal_access_tokens' do
      let!(:existing_token) { create(:personal_access_token, user: service_account_user, scopes: scopes) }

      it 'lists tokens for the service account' do
        get api(base_path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.pluck('id')).to include(existing_token.id)
      end
    end

    describe 'DELETE /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id' do
      let!(:token) { create(:personal_access_token, user: service_account_user) }

      it 'revokes the specified token' do
        delete api("#{base_path}/#{token.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token.reload).to be_revoked
      end

      it 'returns 404 for non-existent token' do
        delete api("#{base_path}/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'POST /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate' do
      let!(:token) { create(:personal_access_token, user: service_account_user) }

      it 'rotates the specified token' do
        post api("#{base_path}/#{token.id}/rotate", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['token']).to be_present
        expect(json_response['id']).not_to eq(token.id)
      end

      it 'returns 404 when token does not belong to the service account' do
        other_token = create(:personal_access_token)

        post api("#{base_path}/#{other_token.id}/rotate", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
