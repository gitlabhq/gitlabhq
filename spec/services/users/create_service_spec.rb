# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreateService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:organization) { create(:organization) }
    let(:password) { User.random_password }
    let(:admin_user) { create(:admin) }
    let(:email) { 'jd@example.com' }
    let(:base_params) do
      { name: 'John Doe', username: 'jduser', email: email, password: password, organization_id: organization.id }
    end

    context 'with an admin user' do
      let(:service) { described_class.new(admin_user, params) }

      context 'when required parameters are provided' do
        let(:params) { base_params }

        it 'returns a persisted user' do
          expect(service.execute).to be_persisted
        end

        it 'persists the given attributes' do
          user = service.execute
          user.reload

          expect(user).to have_attributes(
            name: params[:name],
            username: params[:username],
            email: params[:email],
            password: params[:password],
            created_by_id: admin_user.id
          )
        end

        context 'with user_detail created' do
          it 'creates the user_detail record' do
            expect { service.execute }.to change { UserDetail.count }.by(1)
          end
        end

        context 'when the current_user is not persisted' do
          let(:admin_user) { build(:admin) }

          it 'persists the given attributes and sets created_by_id to nil' do
            user = service.execute
            user.reload

            expect(user).to have_attributes(
              name: params[:name],
              username: params[:username],
              email: params[:email],
              password: params[:password],
              created_by_id: nil
            )
          end
        end

        it 'user is not confirmed if skip_confirmation param is not present' do
          expect(service.execute).not_to be_confirmed
        end

        it 'logs the user creation' do
          expect(service).to receive(:log_info).with("User \"John Doe\" (jd@example.com) was created")

          service.execute
        end

        it 'executes system hooks' do
          system_hook_service = spy(:system_hook_service)

          expect(service).to receive(:system_hook_service).and_return(system_hook_service)

          user = service.execute

          expect(system_hook_service).to have_received(:execute_hooks_for).with(user, :create)
        end

        it 'does not send a notification email' do
          notification_service = spy(:notification_service)

          expect(service).not_to receive(:notification_service)

          service.execute

          expect(notification_service).not_to have_received(:new_user)
        end
      end

      context 'when force_random_password parameter is true' do
        let(:params) { base_params.merge(force_random_password: true) }

        it 'generates random password' do
          user = service.execute

          expect(user.password).not_to eq password
          expect(user.password).to be_present
        end
      end

      context 'when password_automatically_set parameter is true' do
        let(:params) { base_params.merge(password_automatically_set: true) }

        it 'persists the given attributes' do
          user = service.execute
          user.reload

          expect(user).to have_attributes(
            name: params[:name],
            username: params[:username],
            email: params[:email],
            password: params[:password],
            created_by_id: admin_user.id,
            password_automatically_set: params[:password_automatically_set]
          )
        end
      end

      context 'when skip_confirmation parameter is true' do
        let(:params) { base_params.merge(skip_confirmation: true) }

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when reset_password parameter is true' do
        let(:params) { base_params.merge(reset_password: true) }

        it 'resets password even if a password parameter is given' do
          expect(service.execute).to be_recently_sent_password_reset
        end

        it 'sends a notification email' do
          notification_service = spy(:notification_service)

          expect(service).to receive(:notification_service).and_return(notification_service)

          user = service.execute

          expect(notification_service).to have_received(:new_user).with(user, an_instance_of(String))
        end
      end
    end

    context 'with nil user' do
      let(:params) { base_params.merge(skip_confirmation: true) }

      let(:service) { described_class.new(nil, params) }

      it 'persists the given attributes' do
        user = service.execute
        user.reload

        expect(user).to have_attributes(
          name: params[:name],
          username: params[:username],
          email: params[:email],
          password: params[:password],
          created_by_id: nil,
          admin: false
        )
      end

      context 'with user_detail created' do
        it 'creates the user_detail record' do
          expect { service.execute }.to change { UserDetail.count }.by(1)
        end
      end
    end
  end
end
