# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Passkey::DestroyService, feature_category: :system_access do
  let(:user) { create(:user, :with_passkey, registrations_count: 1) }
  let(:current_user) { user }

  describe '#execute' do
    shared_examples 'returns deletion failure' do
      it 'returns a Service.error' do
        expect(destroy_service).to be_a(ServiceResponse)
        expect(destroy_service).to be_error
      end
    end

    shared_examples 'returns deletion success' do
      it 'returns a Service.success' do
        expect(destroy_service).to be_a(ServiceResponse)
        expect(destroy_service).to be_success
      end
    end

    let(:passkey_id) { user.passkeys.first.id }

    subject(:destroy_service) { described_class.new(current_user, user, passkey_id).execute }

    context 'with only one passkey enabled' do
      context 'when another user is calling the service' do
        context 'for an admin', :enable_admin_mode do
          let(:current_user) { create(:admin) }

          it 'destroys the passkey registration' do
            expect { destroy_service }.to change { user.passkeys.count }.by(-1)
          end
        end

        context 'for a user without permissions' do
          let(:current_user) { create(:user) }

          it 'does not destroy the passkey registration' do
            expect { destroy_service }.not_to change { user.passkeys.count }
          end

          it_behaves_like 'returns deletion failure'
        end
      end

      context 'when current user is calling the service' do
        it 'destroys the passkey registration' do
          expect { destroy_service }.to change { user.passkeys.count }.by(-1)
        end

        it_behaves_like 'returns deletion success'
      end
    end

    context 'with multiple passkeys enabled' do
      before do
        create(:webauthn_registration, :passkey, user: user)
      end

      it 'destroys the passkey registration' do
        expect { destroy_service }.to change { user.passkeys.count }.by(-1)
      end

      it_behaves_like 'returns deletion success'
    end
  end
end
