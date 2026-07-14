# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ServiceDesk::CustomEmailController, feature_category: :service_desk do
  let_it_be_with_reload(:project) do
    create(:project, :private, service_desk_enabled: true)
  end

  let_it_be(:custom_email_path) { project_service_desk_custom_email_path(project, format: :json) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:illegitimite_user) { create(:user, developer_of: project) }

  let(:message) { instance_double(Mail::Message) }
  let(:error_cannot_create_custom_email) { s_("ServiceDesk|Cannot create custom email") }
  let(:error_cannot_update_custom_email) { s_("ServiceDesk|Cannot update custom email") }
  let(:error_does_not_exist) { s_('ServiceDesk|Custom email does not exist') }
  let(:error_custom_email_exists) { s_('ServiceDesk|Custom email already exists') }

  let(:custom_email_params) do
    {
      custom_email: 'user@example.com',
      smtp_address: 'smtp.example.com',
      smtp_port: '587',
      smtp_username: 'user@example.com',
      smtp_password: 'supersecret'
    }
  end

  let(:empty_json_response) do
    {
      "custom_email" => nil,
      "custom_email_enabled" => false,
      "custom_email_verification_state" => nil,
      "custom_email_verification_error" => nil,
      "custom_email_smtp_address" => nil,
      "error_message" => nil
    }
  end

  shared_examples 'a json response with empty values' do
    it 'returns json response with empty values' do
      perform_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(empty_json_response)
    end
  end

  shared_examples 'a controller that responds with status' do |status|
    it "responds with #{status} for GET custom email" do
      get custom_email_path
      expect(response).to have_gitlab_http_status(status)
    end

    it "responds with #{status} for POST custom email" do
      post custom_email_path
      expect(response).to have_gitlab_http_status(status)
    end

    it "responds with #{status} for PUT custom email" do
      put custom_email_path
      expect(response).to have_gitlab_http_status(status)
    end

    it "responds with #{status} for DELETE custom email" do
      delete custom_email_path
      expect(response).to have_gitlab_http_status(status)
    end
  end

  shared_examples 'a deletable resource' do
    describe 'DELETE custom email' do
      let(:perform_request) { delete custom_email_path }

      it_behaves_like 'a json response with empty values'
    end
  end

  context 'with legitimate user signed in' do
    before do
      sign_out(illegitimite_user)
      sign_in(user)
    end

    describe 'GET custom email' do
      let(:perform_request) { get custom_email_path }

      it_behaves_like 'a json response with empty values'
    end

    describe 'POST custom email' do
      before do
        # We send verification email directly
        allow(message).to receive(:deliver)
        allow(Notify).to receive(:service_desk_custom_email_verification_email).and_return(message)
      end

      it 'adds custom email and kicks of verification' do
        post custom_email_path, params: custom_email_params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          "custom_email" => custom_email_params[:custom_email],
          "custom_email_enabled" => false,
          "custom_email_verification_state" => "started",
          "custom_email_verification_error" => nil,
          "custom_email_smtp_address" => custom_email_params[:smtp_address],
          "error_message" => nil
        )
      end

      context 'when custom_email param is not valid' do
        it 'does not add custom email' do
          post custom_email_path, params: custom_email_params.merge(custom_email: 'useratexample.com')

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to include(
            empty_json_response.merge("error_message" => error_cannot_create_custom_email)
          )
        end
      end

      context 'when smtp_password param is not valid' do
        it 'does not add custom email' do
          post custom_email_path, params: custom_email_params.merge(smtp_password: '2short')

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to include(
            empty_json_response.merge("error_message" => error_cannot_create_custom_email)
          )
        end
      end

      context 'when the verification process fails fast' do
        before do
          # Could not establish connection, invalid host etc.
          allow(message).to receive(:deliver).and_raise(SocketError)
        end

        it 'adds custom email and kicks of verification and returns verification error state' do
          post custom_email_path, params: custom_email_params

          # In terms of "custom email object creation", failing fast on the
          # verification is a legit state that we don't treat as an error.
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(
            "custom_email" => custom_email_params[:custom_email],
            "custom_email_enabled" => false,
            "custom_email_verification_state" => "failed",
            "custom_email_verification_error" => "smtp_host_issue",
            "custom_email_smtp_address" => custom_email_params[:smtp_address],
            "error_message" => nil
          )
        end
      end
    end

    describe 'PUT custom email' do
      let(:custom_email_params) { { custom_email_enabled: true } }

      it 'does not update records' do
        put custom_email_path, params: custom_email_params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to include(
          empty_json_response.merge("error_message" => error_cannot_update_custom_email)
        )
      end
    end

    describe 'DELETE custom email' do
      it 'does not touch any records' do
        delete custom_email_path

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response).to include(
          empty_json_response.merge("error_message" => error_does_not_exist)
        )
      end
    end

    context 'when custom email is set up' do
      let!(:settings) { create(:service_desk_setting, project: project, custom_email: 'user@example.com') }
      let!(:credential) { create(:service_desk_custom_email_credential, project: project) }

      before do
        project.reset
      end

      context 'and verification started' do
        let!(:verification) do
          create(:service_desk_custom_email_verification, project: project)
        end

        it_behaves_like 'a deletable resource'

        describe 'GET custom email' do
          it 'returns custom email in its current state' do
            get custom_email_path

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "started",
              "custom_email_verification_error" => nil,
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => nil
            )
          end
        end

        describe 'POST custom email' do
          it 'returns custom email in its current state' do
            post custom_email_path, params: custom_email_params

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response).to include(
              "custom_email" => custom_email_params[:custom_email],
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "started",
              "custom_email_verification_error" => nil,
              "custom_email_smtp_address" => custom_email_params[:smtp_address],
              "error_message" => error_custom_email_exists
            )
          end
        end

        describe 'PUT custom email' do
          let(:custom_email_params) { { custom_email_enabled: true } }

          it 'marks custom email as enabled' do
            put custom_email_path, params: custom_email_params

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "started",
              "custom_email_verification_error" => nil,
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => error_cannot_update_custom_email
            )
          end
        end
      end

      context 'and verification finished' do
        let!(:verification) do
          create(:service_desk_custom_email_verification, project: project, state: :finished, token: nil)
        end

        it_behaves_like 'a deletable resource'

        describe 'GET custom email' do
          it 'returns custom email in its current state' do
            get custom_email_path

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "finished",
              "custom_email_verification_error" => nil,
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => nil
            )
          end
        end

        describe 'PUT custom email' do
          let(:custom_email_params) { { custom_email_enabled: true } }

          it 'marks custom email as enabled' do
            put custom_email_path, params: custom_email_params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => true,
              "custom_email_verification_state" => "finished",
              "custom_email_verification_error" => nil,
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => nil
            )
          end
        end
      end

      context 'and verification failed' do
        let!(:verification) do
          create(:service_desk_custom_email_verification,
            project: project,
            state: :failed,
            token: nil,
            error: :smtp_host_issue
          )
        end

        it_behaves_like 'a deletable resource'

        describe 'GET custom email' do
          it 'returns custom email in its current state' do
            get custom_email_path

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "failed",
              "custom_email_verification_error" => "smtp_host_issue",
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => nil
            )
          end
        end

        describe 'PUT custom email' do
          let(:custom_email_params) { { custom_email_enabled: true } }

          it 'does not mark custom email as enabled' do
            put custom_email_path, params: custom_email_params

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response).to include(
              "custom_email" => "user@example.com",
              "custom_email_enabled" => false,
              "custom_email_verification_state" => "failed",
              "custom_email_verification_error" => "smtp_host_issue",
              "custom_email_smtp_address" => "smtp.example.com",
              "error_message" => error_cannot_update_custom_email
            )
          end
        end
      end
    end
  end

  context 'when user is anonymous' do
    before do
      sign_out(user)
      sign_out(illegitimite_user)
    end

    # because Projects::ApplicationController :authenticate_user! responds
    # with redirect to login page
    it_behaves_like 'a controller that responds with status', :found
  end

  context 'with illegitimate user signed in' do
    before do
      sign_out(user)
      sign_in(illegitimite_user)
    end

    it_behaves_like 'a controller that responds with status', :not_found
  end
end
