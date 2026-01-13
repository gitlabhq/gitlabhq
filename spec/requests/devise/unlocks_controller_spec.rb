# frozen_string_literal: true

require 'spec_helper'

# Specs added to detect changes in upstream, and possible differences with Organizations
RSpec.describe Devise::UnlocksController, :with_current_organization, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }
  let(:organization) { user.organization }
  let!(:raw_unlock_token) { user.lock_access! }

  describe '#show with organization route' do
    it 'unlocks the user' do
      expect do
        get organization_user_unlock_path(organization, unlock_token: raw_unlock_token)
      end.to change { user.reload.access_locked? }.from(true).to(false)

      expect(response).to be_redirect
    end

    it 'does not unlock the user with incorrect access token' do
      expect do
        get organization_user_unlock_path(organization, unlock_token: SecureRandom.hex)
      end.not_to change { user.reload.access_locked? }

      expect(response).to be_ok
      expect(response.body).to include(%r{Unlock token(.*)invalid})
    end

    context 'when user cannot be found because incorrect organization specified' do
      let(:another_organization) { create(:organization) }

      before do
        stub_current_organization(another_organization)
      end

      it 'does not unlock user with invalid organization' do
        expect do
          get organization_user_unlock_path(another_organization, unlock_token: raw_unlock_token)
        end.not_to change { user.reload.access_locked? }

        expect(response).to be_ok
        expect(response.body).to include('Organization is invalid')
      end
    end
  end

  describe '#show' do
    it 'unlocks the user' do
      expect do
        get user_unlock_path(unlock_token: raw_unlock_token)
      end.to change { user.reload.access_locked? }.from(true).to(false)

      expect(response).to be_redirect
    end

    it 'does not unlock the user with incorrect access token' do
      expect do
        get user_unlock_path(unlock_token: SecureRandom.hex)
      end.not_to change { user.reload.access_locked? }

      expect(response).to be_ok
      expect(response.body).to include(%r{Unlock token(.*)invalid})
    end
  end
end
