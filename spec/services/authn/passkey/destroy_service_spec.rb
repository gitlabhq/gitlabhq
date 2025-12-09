# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Passkey::DestroyService, feature_category: :system_access do
  let(:user) { create(:user, :with_passkey, registrations_count: 1) }
  let(:current_user) { user }

  describe '#execute' do
    shared_examples 'deletion failure' do
      it 'does not destroy the passkey registration' do
        expect { execute }.not_to change { user.passkeys.count }
      end

      it 'does not send notification email' do
        allow(NotificationService).to receive(:new)
        expect(NotificationService).not_to receive(:new)

        execute
      end

      it 'returns a Service.error' do
        expect(execute).to be_a(ServiceResponse)
        expect(execute).to be_error
      end
    end

    shared_examples 'deletion success' do
      it 'destroys the passkey registration' do
        expect { execute }.to change { user.passkeys.count }.by(-1)
      end

      it 'sends the user notification email' do
        expect_next_instance_of(NotificationService) do |notification|
          expect(notification).to receive(:disabled_two_factor).with(
            user, :passkey, { device_name: passkey.name }
          )
        end

        execute
      end

      it 'returns a Service.success' do
        expect(execute).to be_a(ServiceResponse)
        expect(execute).to be_success
      end
    end

    let(:passkey) { user.passkeys.first }
    let(:passkey_id) { passkey.id }

    subject(:execute) { described_class.new(current_user, user, passkey_id).execute }

    context 'with only one passkey enabled' do
      context 'when another user is calling the service' do
        context 'for an admin', :enable_admin_mode do
          let(:current_user) { create(:admin) }

          it_behaves_like 'deletion success'
        end

        context 'for a user without permissions' do
          let(:current_user) { create(:user) }

          it_behaves_like 'deletion failure'
        end
      end

      context 'when current user is calling the service' do
        it_behaves_like 'deletion success'
      end
    end

    context 'with multiple passkeys enabled' do
      before do
        create(:webauthn_registration, :passkey, user: user)
      end

      it_behaves_like 'deletion success'
    end
  end
end
