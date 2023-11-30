# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomEmails::CreateService, feature_category: :service_desk do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:service) { described_class.new(project: project, current_user: user, params: params) }
    let(:error_user_not_authorized) { s_('ServiceDesk|User cannot manage project.') }
    let(:error_cannot_create_custom_email) { s_('ServiceDesk|Cannot create custom email') }
    let(:error_custom_email_exists) { s_('ServiceDesk|Custom email already exists') }
    let(:error_params_missing) { s_('ServiceDesk|Parameters missing') }
    let(:expected_error_message) { nil }
    let(:params) { {} }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
    let(:message) { instance_double(Mail::Message) }
    let(:logger_params) { { category: 'custom_email' } }

    shared_examples 'a service that exits with error' do
      it 'exits early' do
        expect(Gitlab::AppLogger).to receive(:warn).with(logger_params.merge(
          error_message: expected_error_message
        )).once

        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq(expected_error_message)
      end
    end

    shared_examples 'a failing service that does not create records' do
      it 'exits with error and does not create records' do
        expect(Gitlab::AppLogger).to receive(:warn).with(logger_params.merge(
          error_message: expected_error_message
        )).once

        response = service.execute
        project.reset

        expect(response).to be_error
        expect(response.message).to eq(expected_error_message)
        expect(project.service_desk_custom_email_verification).to be nil
        expect(project.service_desk_custom_email_credential).to be nil
        expect(project.service_desk_setting).to have_attributes(
          custom_email: nil,
          custom_email_enabled: false
        )
      end
    end

    context 'with illegitimate user' do
      let(:expected_error_message) { error_user_not_authorized }

      before do
        stub_member_access_level(project, developer: user)
      end

      it_behaves_like 'a service that exits with error'
    end

    context 'with legitimate user' do
      let!(:settings) { create(:service_desk_setting, project: project) }

      let(:expected_error_message) { error_params_missing }

      before do
        stub_member_access_level(project, maintainer: user)

        # We send verification email directly and it will fail with
        # smtp.example.com because it expects a valid DNS record
        allow(message).to receive(:deliver)
        allow(Notify).to receive(:service_desk_custom_email_verification_email).and_return(message)
      end

      it_behaves_like 'a service that exits with error'

      context 'with params but custom_email missing' do
        let(:params) do
          {
            smtp_address: 'smtp.example.com',
            smtp_port: '587',
            smtp_username: 'user@example.com',
            smtp_password: 'supersecret'
          }
        end

        it_behaves_like 'a failing service that does not create records'
      end

      context 'with params but smtp username empty' do
        let(:params) do
          {
            custom_email: 'user@example.com',
            smtp_address: 'smtp.example.com',
            smtp_port: '587',
            smtp_username: nil,
            smtp_password: 'supersecret'
          }
        end

        it_behaves_like 'a failing service that does not create records'
      end

      context 'with params but smtp password is too short' do
        let(:expected_error_message) { error_cannot_create_custom_email }
        let(:params) do
          {
            custom_email: 'user@example.com',
            smtp_address: 'smtp.example.com',
            smtp_port: '587',
            smtp_username: 'user@example.com',
            smtp_password: '2short'
          }
        end

        it_behaves_like 'a failing service that does not create records'
      end

      context 'with params but custom_email is invalid' do
        let(:expected_error_message) { error_cannot_create_custom_email }
        let(:params) do
          {
            custom_email: 'useratexampledotcom',
            smtp_address: 'smtp.example.com',
            smtp_port: '587',
            smtp_username: 'user@example.com',
            smtp_password: 'supersecret'
          }
        end

        it_behaves_like 'a failing service that does not create records'
      end

      context 'with full set of params' do
        let(:params) do
          {
            custom_email: 'user@example.com',
            smtp_address: 'smtp.example.com',
            smtp_port: '587',
            smtp_username: 'user@example.com',
            smtp_password: 'supersecret'
          }
        end

        it 'creates all records and returns a successful response' do
          # Because we also log in ServiceDesk::CustomEmailVerifications::CreateService
          expect(Gitlab::AppLogger).to receive(:info).with({ category: 'custom_email_verification' }).once
          expect(Gitlab::AppLogger).to receive(:info).with(logger_params).once

          response = service.execute
          project.reset

          expect(response).to be_success

          expect(project.service_desk_setting).to have_attributes(
            custom_email: params[:custom_email],
            custom_email_enabled: false
          )
          expect(project.service_desk_custom_email_credential).to have_attributes(
            smtp_address: params[:smtp_address],
            smtp_port: params[:smtp_port].to_i,
            smtp_username: params[:smtp_username],
            smtp_password: params[:smtp_password],
            smtp_authentication: nil
          )
          expect(project.service_desk_custom_email_verification).to have_attributes(
            state: 'started',
            triggerer: user,
            error: nil
          )
        end

        context 'with optional smtp_authentication parameter' do
          before do
            params[:smtp_authentication] = 'login'
          end

          it 'sets authentication and returns a successful response' do
            response = service.execute
            project.reset

            expect(response).to be_success
            expect(project.service_desk_custom_email_credential.smtp_authentication).to eq 'login'
          end

          context 'with unsupported value' do
            let(:expected_error_message) { error_cannot_create_custom_email }

            before do
              params[:smtp_authentication] = 'unsupported'
            end

            it_behaves_like 'a failing service that does not create records'
          end
        end

        context 'when custom email aready exists' do
          let!(:settings) { create(:service_desk_setting, project: project, custom_email: 'user@example.com') }
          let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
          let!(:verification) { create(:service_desk_custom_email_verification, project: project) }

          let(:expected_error_message) { error_custom_email_exists }

          it_behaves_like 'a service that exits with error'
        end
      end
    end
  end
end
