# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ServiceAccounts, :with_current_organization, :aggregate_failures, :clean_gitlab_redis_rate_limiting,
  feature_category: :user_management do
  let_it_be(:user)  { create(:user, organizations: [current_organization]) }
  let_it_be(:admin) { create(:admin, organizations: [current_organization]) }

  describe "POST /service_accounts" do
    subject(:perform_request_as_admin) { post api("/service_accounts", admin, admin_mode: true), params: params }

    let_it_be(:params) { {} }

    context 'when user is an admin' do
      it "creates user with user type service_account_user" do
        perform_request_as_admin

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['username']).to start_with('service_account')
      end

      context 'when params are provided' do
        let_it_be(:params) do
          {
            name: 'John Doe',
            username: 'test'
          }
        end

        it "creates user with provided details" do
          perform_request_as_admin

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['username']).to eq(params[:username])
          expect(json_response['name']).to eq(params[:name])
          expect(json_response['email']).to start_with('service_account')
          expect(response).to match_response_schema('public_api/v4/user/service_account')
        end

        context 'when specifying a custom email address' do
          let(:email) { 'service_account@example.com' }

          before do
            post api("/service_accounts", admin, admin_mode: true),
              params: params.merge(email: email)
          end

          it "sets to correct email" do
            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['username']).to eq(params[:username])
            expect(json_response['name']).to eq(params[:name])
            expect(json_response['email']).to eq(email)
            expect(response).to match_response_schema('public_api/v4/user/service_account')
          end

          context 'when user with the email already exists' do
            before do
              post api("/service_accounts", admin, admin_mode: true),
                params: params.merge(email: email)
            end

            it 'returns error' do
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to include('Email has already been taken')
            end
          end
        end

        context 'when user with the username already exists' do
          before do
            post api("/service_accounts", admin, admin_mode: true), params: params
          end

          it 'returns error' do
            perform_request_as_admin

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Username has already been taken')
          end
        end
      end

      it 'returns bad request error when service returns bad request' do
        allow_next_instance_of(::Users::ServiceAccounts::CreateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'something went wrong', reason: :bad_request)
          )
        end

        perform_request_as_admin

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when user is not an admin' do
      it "returns error" do
        post api("/service_accounts", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :create_service_account do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { post api("/service_accounts", personal_access_token: pat), params: params }
    end

    context 'for rate limiting' do
      let_it_be(:admin2) { create(:admin) }

      let(:current_user) { admin }

      def request
        post api("/service_accounts", admin, admin_mode: true), params: params
      end

      def request_with_second_scope
        post api("/service_accounts", admin2, admin_mode: true), params: params
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :service_account_creation
    end
  end

  describe "GET /service_accounts" do
    let_it_be(:service_account_buser) { create(:user, :service_account, username: "Buser") }
    let_it_be(:service_account_auser) { create(:user, :service_account, username: "Auser") }
    let_it_be(:regular_user) { create(:user) }
    let(:path) { "/service_accounts" }
    let_it_be(:params) { {} }

    subject(:perform_request) { get api(path, admin, admin_mode: true), params: params }

    context 'when params are empty' do
      before do
        perform_request
      end

      it 'returns 200 status service account users list' do
        expect(response).to have_gitlab_http_status(:ok)

        expect(response).to match_response_schema('public_api/v4/user/service_accounts')
        expect(json_response.size).to eq(2)

        expect_paginated_array_response(service_account_auser.id, service_account_buser.id)
        expect(json_response.pluck("id")).not_to include(regular_user.id)
      end
    end

    context 'when params has order_by specified' do
      context 'when username' do
        let_it_be(:params) { { order_by: "username" } }

        it 'orders by username in desc order' do
          perform_request

          expect_paginated_array_response(service_account_buser.id, service_account_auser.id)
        end

        context 'when sort order is specified' do
          let_it_be(:params) { { order_by: "username", sort: "asc" } }

          it 'follows sort order' do
            perform_request

            expect_paginated_array_response(service_account_auser.id, service_account_buser.id)
          end
        end
      end

      context 'when order_by is neither id or username' do
        let_it_be(:params) { { order_by: "name" } }

        it 'throws error' do
          perform_request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    it_behaves_like 'an endpoint with keyset pagination', invalid_order: nil do
      let(:first_record) { service_account_auser }
      let(:second_record) { service_account_buser }
      let(:api_call) { api(path, admin, admin_mode: true) }
    end

    it_behaves_like 'authorizing granular token permissions', :read_service_account do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { get api(path, personal_access_token: pat) }
    end
  end

  describe "PATCH /service_accounts/:user_id" do
    let_it_be(:params) { { name: 'Updated Name', username: 'updated_username', email: 'test@test.com' } }
    let_it_be(:service_account_user) { create(:user, :service_account, username: "sa_user") }

    subject(:perform_request) do
      patch api("/service_accounts/#{service_account_user.id}", current_user), params: params
    end

    context 'when current user is an admin' do
      let(:current_user) { admin }

      context 'when admin mode is not enabled' do
        it "returns forbidden error" do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'updates the service account user' do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.keys).to match_array(%w[id name username email public_email])
          expect(json_response['name']).to eq(params[:name])
          expect(json_response['username']).to eq(params[:username])
          expect(json_response['email']).to eq(params[:email])
        end

        context 'when email confirmation is required' do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'hard')

            allow(Devise::Mailer).to receive(:confirmation_instructions).and_return(mailer_double)
            allow(mailer_double).to receive(:deliver_later)
          end

          let(:mailer_double) { instance_double(ActionMailer::MessageDelivery) }

          it 'only updates the unconfirmed email' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.keys).to match_array(%w[id name username email public_email unconfirmed_email])
            expect(json_response['unconfirmed_email']).to eq('test@test.com')
            expect(json_response['email']).not_to eq('test@test.com')
          end

          it 'sends a confirmation email' do
            expect(mailer_double).to receive(:deliver_later)

            perform_request
          end
        end

        context 'when user with the username already exists' do
          let(:existing_user) { create(:user, username: 'existing_user') }
          let(:params) { { username: existing_user.username } }

          it 'returns error' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include('Username has already been taken')
          end
        end

        it "returns a 404 for a non-existing user" do
          patch api("/service_accounts/#{non_existing_record_id}", current_user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end

        it "returns a 400 for and invalid user ID" do
          patch api("/service_accounts/ASDF", current_user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it "returns a 400 for a non-service account user" do
          patch api("/service_accounts/#{user.id}", current_user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to include('User is not a service account')
        end

        context 'with an enforced composite_identity' do
          before do
            service_account_user.update!(composite_identity_enforced: true)
          end

          context 'when attempting to update the username' do
            it 'returns a 400 error' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to include(
                'You cannot update the username of a service account associated with a composite identity.'
              )
            end
          end

          context 'when updating only the name and email' do
            let(:params) { { name: 'Updated Name', email: 'updated@example.com' } }

            it 'updates the service account' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['name']).to eq(params[:name])
              expect(json_response['email']).to eq(params[:email])
            end
          end
        end
      end
    end

    context 'when current user is not an admin' do
      before do
        group = create(:group)
        group.add_maintainer(user)
      end

      let(:current_user) { user }

      it "returns forbidden error" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :update_service_account do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) do
        patch api("/service_accounts/#{service_account_user.id}", personal_access_token: pat), params: params
      end
    end
  end
end
