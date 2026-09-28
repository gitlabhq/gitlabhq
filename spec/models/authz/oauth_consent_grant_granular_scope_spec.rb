# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::OauthConsentGrantGranularScope, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:oauth_consent_grant).required }
    it { is_expected.to belong_to(:granular_scope).required }
  end

  describe 'sharding key' do
    let_it_be(:grant) { create(:oauth_consent_grant) }

    subject { build(:oauth_consent_grant_granular_scope, oauth_consent_grant: grant, organization_id: nil) }

    it { is_expected.to populate_sharding_key(:organization_id).with(grant.organization_id) }
  end

  describe 'orphaned granular scope cleanup' do
    let(:granular_scope) { create(:granular_scope, namespace: nil, access: :user) }
    let!(:consent_grant_link) { create(:oauth_consent_grant_granular_scope, granular_scope: granular_scope) }

    def granular_scope_exists?
      Authz::GranularScope.exists?(granular_scope.id)
    end

    # `delete` skips ActiveRecord callbacks, so these examples exercise the database trigger itself
    it 'deletes the granular scope when its last consent grant link is deleted' do
      consent_grant_link.delete

      expect(granular_scope_exists?).to be(false)
    end

    it 'deletes the granular scope when the consent grant itself is deleted' do
      consent_grant_link.oauth_consent_grant.delete

      expect(granular_scope_exists?).to be(false)
    end

    it 'deletes the grant and the granular scope when the application is destroyed' do
      grant = consent_grant_link.oauth_consent_grant

      grant.application.destroy!

      expect(Authz::OauthConsentGrant.exists?(grant.id)).to be(false)
      expect(granular_scope_exists?).to be(false)
    end

    context 'when a personal access token also links the granular scope' do
      let!(:token_link) { create(:personal_access_token_granular_scope, granular_scope: granular_scope) }

      it 'keeps the granular scope when the consent grant link is deleted' do
        consent_grant_link.delete

        expect(granular_scope_exists?).to be(true)
      end

      it 'keeps the granular scope when the personal access token link is deleted' do
        token_link.delete

        expect(granular_scope_exists?).to be(true)
      end

      it 'deletes the granular scope once both links are deleted' do
        consent_grant_link.delete
        token_link.delete

        expect(granular_scope_exists?).to be(false)
      end
    end
  end
end
