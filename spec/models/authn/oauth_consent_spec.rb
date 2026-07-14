# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthConsent, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:application).class_name('Authn::OauthApplication') }
  end

  describe 'validations' do
    subject(:consent) { build(:oauth_consent) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:consent_challenge) }
    it { is_expected.to validate_presence_of(:granted_scopes) }
    it { is_expected.to validate_presence_of(:requested_scopes) }

    it 'validates uniqueness of consent_challenge' do
      create(:oauth_consent, consent_challenge: consent.consent_challenge)
      is_expected.to validate_uniqueness_of(:consent_challenge)
    end

    context 'when consent is revoked' do
      subject(:consent) { create(:oauth_consent, :revoked) }

      it 'prevents any status change', :aggregate_failures do
        consent.status = 'authorized'

        expect(consent).not_to be_valid
        expect(consent.errors[:status]).to include('revoked consent cannot be modified')
      end
    end

    context 'when consent is rejected' do
      subject(:consent) { create(:oauth_consent, :rejected) }

      it 'prevents any status change', :aggregate_failures do
        consent.status = 'authorized'

        expect(consent).not_to be_valid
        expect(consent.errors[:status]).to include('rejected consent cannot be modified')
      end
    end

    context 'when consent is authorized' do
      subject(:consent) { create(:oauth_consent) }

      it 'allows scope updates' do
        consent.granted_scopes = %w[openid]

        expect(consent).to be_valid
      end

      it 'allows transition to revoked' do
        consent.status = 'revoked'

        expect(consent).to be_valid
      end
    end
  end

  describe '.latest_per_application' do
    let_it_be(:user) { create(:user) }
    let_it_be(:app_a) { create(:oauth_application) }
    let_it_be(:app_b) { create(:oauth_application) }
    let_it_be(:older_a) { create(:oauth_consent, user: user, application: app_a, created_at: 2.days.ago) }
    let_it_be(:newer_a) { create(:oauth_consent, user: user, application: app_a, created_at: 1.day.ago) }
    let_it_be(:only_b) { create(:oauth_consent, user: user, application: app_b) }

    it 'returns one record per client_id, preferring the most recent created_at' do
      result = described_class.where(user: user).latest_per_application

      expect(result).to contain_exactly(newer_a, only_b)
    end
  end

  describe '.revoke_authorized_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:app) { create(:oauth_application) }

    let!(:authorized) { create(:oauth_consent, user: user, application: app) }
    let!(:other_user_authorized) { create(:oauth_consent, user: other_user, application: app) }
    let!(:already_revoked) { create(:oauth_consent, :revoked, user: user, application: app) }
    let!(:rejected) { create(:oauth_consent, :rejected, user: user, application: app) }

    subject(:revoke) { described_class.revoke_authorized_for(user: user, client_id: app.uid) }

    it 'marks the user\'s authorized consent for the client as revoked' do
      expect { revoke }.to change { authorized.reload.status }.from('authorized').to('revoked')
    end

    it 'does not touch other users\' consents', :aggregate_failures do
      revoke

      expect(other_user_authorized.reload).to be_authorized
    end

    it 'does not touch already-revoked or rejected consents', :aggregate_failures do
      revoke

      expect(already_revoked.reload).to be_revoked
      expect(rejected.reload).to be_rejected
    end
  end
end
