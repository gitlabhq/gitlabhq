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
          expect(user).to be_persisted
        end

        it 'persists the given attributes' do
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
          expect(user).not_to be_confirmed
        end

        it 'logs the user creation' do
          expect(service).to receive(:log_info).with("User \"John Doe\" (jd@example.com) was created")

          service.execute
        end

        it 'executes system hooks' do
          system_hook_service = spy(:system_hook_service)

          expect(service).to receive(:system_hook_service).and_return(system_hook_service)

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
          expect(user.password).not_to eq password
          expect(user.password).to be_present
        end
      end

      context 'when password_automatically_set parameter is true' do
        let(:params) { base_params.merge(password_automatically_set: true) }

        it 'persists the given attributes' do
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
          expect(user).to be_confirmed
        end
      end

      context 'when reset_password parameter is true' do
        let(:params) { base_params.merge(reset_password: true) }

        it 'resets password even if a password parameter is given' do
          expect(user).to be_recently_sent_password_reset
        end

        it 'sends a notification email' do
          notification_service = spy(:notification_service)

          expect(service).to receive(:notification_service).and_return(notification_service)

          expect(notification_service).to have_received(:new_user).with(user, an_instance_of(String))
        end
      end

      context 'when user has errors' do
        let(:params) { base_params }

        before do
          user = build(:user, email: 'invalid_email_format')

          allow(service).to receive(:user).and_return(user)
        end

        it 'does not create a user' do
          expect { service.execute }.not_to change { User.count }
        end

        it 'does not return a persisted user' do
          expect(user).not_to be_persisted
        end

        it 'returns an error' do
          expect(service.execute).to have_attributes(message: 'Email is invalid', status: :error)
        end
      end
    end

    context 'with nil user' do
      let(:params) { base_params.merge(skip_confirmation: true) }

      let(:service) { described_class.new(nil, params) }

      it 'persists the given attributes' do
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

    def user
      service.execute.payload[:user]
    end
  end

  describe 'Organization Administrator role sync' do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:organization) { create(:organization) }

    let(:params) do
      {
        name: 'John Doe',
        username: 'jduser',
        email: 'jd@example.com',
        password: User.random_password,
        organization_id: organization.id
      }
    end

    subject(:service) { described_class.new(current_user, params) }

    before do
      allow(Authz::Organizations::OwnerRoleSync).to receive(:enabled?).and_return(true)
    end

    context 'when the user is created as an organization owner' do
      let(:params) { super().merge(organization_access_level: 'owner') }

      it 'enqueues GrantOwnerRoleWorker for the new user with the creating admin as the acting user' do
        enqueued = nil
        expect(Authz::Organizations::GrantOwnerRoleWorker).to receive(:perform_async).once { |*args| enqueued = args }

        user = service.execute.payload[:user]

        expect(enqueued).to eq([organization.id, user.id, current_user.id])
      end

      context 'when the owner role sync is unavailable' do
        before do
          allow(Authz::Organizations::OwnerRoleSync).to receive(:enabled?).and_return(false)
        end

        it 'does not enqueue GrantOwnerRoleWorker', :aggregate_failures do
          expect(Authz::Organizations::GrantOwnerRoleWorker).not_to receive(:perform_async)

          expect(service.execute).to be_success
        end
      end
    end

    context 'when the user is created with the default access level' do
      it 'does not enqueue GrantOwnerRoleWorker', :aggregate_failures do
        expect(Authz::Organizations::GrantOwnerRoleWorker).not_to receive(:perform_async)

        expect(service.execute).to be_success
      end
    end

    # Without a creator only signup params are accepted, so no owner row can
    # be written and the hook never reaches the actor id.
    context 'when there is no current user' do
      let(:params) { super().merge(organization_access_level: 'owner', admin: true, skip_confirmation: true) }

      subject(:service) { described_class.new(nil, params) }

      it 'does not enqueue GrantOwnerRoleWorker and does not raise', :aggregate_failures do
        expect(Authz::Organizations::GrantOwnerRoleWorker).not_to receive(:perform_async)

        expect(service.execute).to be_success
      end
    end

    # The admin flag makes the new user an owner of their home organization;
    # the worker, not this hook, decides that such a row gets no tuple.
    context 'when the user is created with the admin flag' do
      let(:params) { super().merge(admin: true) }

      it 'enqueues GrantOwnerRoleWorker for the home organization owner row' do
        enqueued = nil
        expect(Authz::Organizations::GrantOwnerRoleWorker).to receive(:perform_async).once { |*args| enqueued = args }

        user = service.execute.payload[:user]

        expect(enqueued).to eq([organization.id, user.id, current_user.id])
      end

      # The production admin fixture bootstraps the first admin with a
      # non-persisted admin as the creator, so there is no actor id to pass.
      context 'when the creating admin is not persisted' do
        let(:current_user) { build(:admin) }

        it 'enqueues GrantOwnerRoleWorker without an actor' do
          enqueued = nil
          expect(Authz::Organizations::GrantOwnerRoleWorker).to receive(:perform_async).once { |*args| enqueued = args }

          user = service.execute.payload[:user]

          expect(enqueued).to eq([organization.id, user.id, nil])
        end
      end
    end
  end
end
