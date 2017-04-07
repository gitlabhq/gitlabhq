require 'spec_helper'

describe Users::CreateService, services: true do
  describe '#build' do
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
    end

    context 'with an admin user' do
      let(:admin_user) { create(:admin) }
      let(:service) { described_class.new(admin_user, params) }

      it 'returns a valid user' do
        expect(service.build).to be_valid
      end
    end

    context 'with non admin user' do
      let(:user) { create(:user) }
      let(:service) { described_class.new(user, params) }

      it 'raises AccessDeniedError exception' do
        expect { service.build }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'with nil user' do
      let(:service) { described_class.new(nil, params) }

      it 'returns a valid user' do
        expect(service.build).to be_valid
      end
    end
  end

  describe '#execute' do
    let(:admin_user) { create(:admin) }

    context 'with an admin user' do
      let(:service) { described_class.new(admin_user, params) }

      context 'when required parameters are provided' do
        let(:params) do
          { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
        end

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

        it 'executes system hooks ' do
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
        let(:params) do
          { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass', force_random_password: true }
        end

        it 'generates random password' do
          user = service.execute

          expect(user.password).not_to eq 'mydummypass'
          expect(user.password).to be_present
        end
      end

      context 'when password_automatically_set parameter is true' do
        let(:params) do
          {
            name: 'John Doe',
            username: 'jduser',
            email: 'jd@example.com',
            password: 'mydummypass',
            password_automatically_set: true
          }
        end

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
        let(:params) do
          { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass', skip_confirmation: true }
        end

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when reset_password parameter is true' do
        let(:params) do
          { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass', reset_password: true }
        end

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
      let(:params) do
        { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass', skip_confirmation: true }
      end
      let(:service) { described_class.new(nil, params) }

      context 'when "send_user_confirmation_email" application setting is true' do
        before do
          current_application_settings = double(:current_application_settings, send_user_confirmation_email: true, signup_enabled?: true)
          allow(service).to receive(:current_application_settings).and_return(current_application_settings)
        end

        it 'does not confirm the user' do
          expect(service.execute).not_to be_confirmed
        end
      end

      context 'when "send_user_confirmation_email" application setting is false' do
        before do
          current_application_settings = double(:current_application_settings, send_user_confirmation_email: false, signup_enabled?: true)
          allow(service).to receive(:current_application_settings).and_return(current_application_settings)
        end

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end

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
      end
    end
  end
end
