# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::OauthConsentGrants::RevokeService, :aggregate_failures, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application) }

  let(:service) { described_class.new(user: user, application_id: application.id, ip_address: '127.0.0.1') }

  subject(:response) { service.execute }

  context 'with an active consent grant' do
    let_it_be_with_reload(:grant) do
      create(:oauth_consent_grant, user: user, application: application,
        boundary: Authz::Boundary.for(:instance), permissions: :create_member_role)
    end

    let_it_be_with_reload(:duo_session_grant) do
      create(:oauth_consent_grant, user: user, application: application, source: :duo_session)
    end

    let!(:token) { create(:oauth_access_token, :granular, resource_owner: user, application: application) }
    let!(:code) do
      create(:oauth_access_grant, resource_owner_id: user.id, application: application, organization: user.organization)
    end

    let!(:other_user_token) { create(:oauth_access_token, :granular, application: application) }

    it 'revokes the grant together with the outstanding tokens and codes for the user and application' do
      expect(response).to be_success
      expect(response.payload[:consent_grant]).to eq(grant).and be_revoked

      expect(grant.reload).to be_revoked
      expect(token.reload).to be_revoked
      expect(code.reload).to be_revoked
    end

    it 'leaves other users and per-session grants untouched' do
      response

      expect(other_user_token.reload).not_to be_revoked
      expect(duo_session_grant.reload).to be_authorized
    end

    it 'emits a revoked audit event' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        name: 'oauth_consent_grant_revoked',
        author: user,
        scope: user,
        target: grant,
        target_details: application.name,
        message: 'Consent for an OAuth application was revoked.',
        additional_details: {
          application_id: application.id,
          application_name: application.name,
          application_owner_type: application.owner_type,
          application_owner_id: application.owner_id,
          source: 'doorkeeper',
          revocation_source: 'user',
          granular_scopes: [{ 'access' => 'instance', 'namespace_id' => nil, 'permissions' => ['create_member_role'] }]
        },
        ip_address: '127.0.0.1'
      )

      response
    end

    it 'accepts the application id as a string' do
      described_class.new(user: user, application_id: application.id.to_s).execute

      expect(grant.reload).to be_revoked
    end

    it 'records the given author and revocation source' do
      admin = create(:admin)

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
        author: admin, scope: user, additional_details: hash_including(revocation_source: 'admin')
      ))

      described_class.new(user: user, application_id: application.id, author: admin, revocation_source: :admin).execute
    end

    it 'keeps the grant when the token revocation fails' do
      allow(Authn::OauthApplication).to receive(:revoke_tokens_and_grants_for).and_raise(StandardError, 'boom')
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      expect { response }.to raise_error(StandardError, 'boom')
      expect(grant.reload).to be_authorized
    end
  end

  context 'without an active consent grant' do
    let_it_be(:revoked_grant) { create(:oauth_consent_grant, :revoked, user: user, application: application) }

    let!(:token) { create(:oauth_access_token, resource_owner: user, application: application) }

    it 'succeeds without changing anything' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      expect(response).to be_success
      expect(response.payload[:consent_grant]).to be_nil
      expect(token.reload).not_to be_revoked
    end
  end
end
