# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authn::OauthApplications::RevokeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application) }
  let!(:grant) { create(:oauth_access_grant, resource_owner_id: user.id, application: application) }
  let!(:access_token) { create(:oauth_access_token, resource_owner: user, application: application) }

  subject(:service) { described_class.new(current_user: user, application_id: application.id.to_s) }

  describe '#execute' do
    it 'revokes both access grants and tokens', :aggregate_failures do
      expect(grant).not_to be_revoked
      expect(access_token).not_to be_revoked

      service.execute

      expect(grant.reload).to be_revoked
      expect(access_token.reload).to be_revoked
    end

    it 'returns a success ServiceResponse' do
      response = service.execute

      expect(response).to be_success
    end

    it 'logs the revocation' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        Labkit::Fields::CLASS_NAME => described_class.name,
        message: "OAuth application authorization revoked",
        revoked_by: user.username,
        revoked_for: user.username,
        application_id: application.id.to_s)

      service.execute
    end

    context 'when iam_svc_oauth is enabled' do
      let!(:consent) { create(:oauth_consent, user: user, application: application) }
      let!(:other_user_consent) { create(:oauth_consent, application: application) }

      before do
        stub_feature_flags(iam_svc_oauth: user)
      end

      it 'revokes oauth_consents for the application and current user', :aggregate_failures do
        service.execute

        expect(consent.reload).to be_revoked
        expect(other_user_consent.reload).to be_authorized
      end

      it 'is a no-op for consents when application is not found' do
        described_class.new(current_user: user, application_id: non_existing_record_id.to_s).execute

        expect(consent.reload).to be_authorized
      end

      it 'rolls back token and grant revocation when consent revocation fails', :aggregate_failures do
        allow(Authn::OauthConsent).to receive(:revoke_authorized_for).and_raise(StandardError, 'boom')

        expect { service.execute }.to raise_error(StandardError, 'boom')

        expect(access_token.reload).not_to be_revoked
        expect(grant.reload).not_to be_revoked
        expect(consent.reload).to be_authorized
      end
    end

    context 'when iam_svc_oauth is disabled' do
      let!(:consent) { create(:oauth_consent, user: user, application: application) }

      before do
        stub_feature_flags(iam_svc_oauth: false)
      end

      it 'does not touch oauth_consents' do
        service.execute

        expect(consent.reload).to be_authorized
      end
    end
  end
end
