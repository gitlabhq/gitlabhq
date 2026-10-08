# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::OauthApplicationGranularScope, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:application).class_name('Authn::OauthApplication').required }
    it { is_expected.to belong_to(:granular_scope).required }
  end

  describe 'sharding key' do
    let_it_be(:application) { create(:oauth_application) }

    subject { build(:oauth_application_granular_scope, application: application, organization_id: nil) }

    it { is_expected.to populate_sharding_key(:organization_id).with(application.organization_id) }
  end

  describe 'orphaned granular scope cleanup' do
    let(:granular_scope) { create(:granular_scope, namespace: nil, access: :user) }
    let!(:application_link) { create(:oauth_application_granular_scope, granular_scope: granular_scope) }

    def granular_scope_exists?
      Authz::GranularScope.exists?(granular_scope.id)
    end

    # `delete` skips ActiveRecord callbacks, so these examples exercise the database trigger itself
    it 'deletes the granular scope when its last application link is deleted' do
      application_link.delete

      expect(granular_scope_exists?).to be(false)
    end

    it 'deletes the link and the granular scope when the application is destroyed' do
      application_link.application.destroy!

      expect(described_class.exists?(application_link.id)).to be(false)
      expect(granular_scope_exists?).to be(false)
    end

    context 'when a consent grant also links the granular scope' do
      let!(:consent_grant_link) { create(:oauth_consent_grant_granular_scope, granular_scope: granular_scope) }

      it 'keeps the granular scope when the application link is deleted' do
        application_link.delete

        expect(granular_scope_exists?).to be(true)
      end

      it 'keeps the granular scope when the consent grant link is deleted' do
        consent_grant_link.delete

        expect(granular_scope_exists?).to be(true)
      end

      it 'deletes the granular scope once both links are deleted' do
        application_link.delete
        consent_grant_link.delete

        expect(granular_scope_exists?).to be(false)
      end
    end

    context 'when a personal access token also links the granular scope' do
      let!(:token_link) { create(:personal_access_token_granular_scope, granular_scope: granular_scope) }

      it 'keeps the granular scope when the application link is deleted' do
        application_link.delete

        expect(granular_scope_exists?).to be(true)
      end

      it 'deletes the granular scope once both links are deleted' do
        application_link.delete
        token_link.delete

        expect(granular_scope_exists?).to be(false)
      end
    end
  end
end
