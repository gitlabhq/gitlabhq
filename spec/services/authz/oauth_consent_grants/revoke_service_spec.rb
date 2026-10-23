# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::OauthConsentGrants::RevokeService, :aggregate_failures, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, :granular) }

  let(:service) { described_class.new(user: user, application_id: application.id) }

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

    it 'deletes the grant with its copied scopes and revokes the outstanding tokens and codes' do
      copied_scope_ids = grant.granular_scopes.ids
      declared_scope_ids = application.granular_scopes.ids

      expect(response).to be_success
      expect(response.payload[:consent_grant]).to eq(grant)

      expect(Authz::OauthConsentGrant.exists?(grant.id)).to be(false)
      expect(Authz::GranularScope.where(id: copied_scope_ids)).to be_empty
      expect(Authz::GranularScope.where(id: declared_scope_ids).ids).to match_array(declared_scope_ids)
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
          granular_scopes: [{ 'access' => 'instance', 'namespace_id' => nil, 'permissions' => ['create_member_role'] }]
        }
      )

      response
    end

    it 'accepts the application id as a string' do
      expect { described_class.new(user: user, application_id: application.id.to_s).execute }
        .to change { Authz::OauthConsentGrant.exists?(grant.id) }.from(true).to(false)
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
