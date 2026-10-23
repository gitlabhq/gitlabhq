# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplications::RevokeNonGranularTokensWorker, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, :granular) }

  let!(:legacy_token) { create(:oauth_access_token, resource_owner: user, application: application, scopes: 'api') }
  let!(:granular_token) { create(:oauth_access_token, :granular, resource_owner: user, application: application) }

  describe '#perform' do
    let(:application_id) { application.id }
    let(:user_id) { user.id }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [application_id, user_id] }

      it 'revokes the legacy tokens and keeps the granular ones', :aggregate_failures do
        perform_idempotent_work

        expect(legacy_token.reload).to be_revoked
        expect(granular_token.reload).not_to be_revoked
      end
    end

    shared_examples 'does nothing' do
      it 'keeps the legacy tokens' do
        expect(Authn::OauthApplication).not_to receive(:revoke_non_granular_tokens_and_grants_for)

        described_class.new.perform(application_id, user_id)

        expect(legacy_token.reload).not_to be_revoked
      end
    end

    context 'when the user no longer exists' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'does nothing'
    end

    context 'when the application no longer exists' do
      let(:application_id) { non_existing_record_id }

      it_behaves_like 'does nothing'
    end

    context 'when the application no longer declares granular scopes' do
      before do
        Authz::OauthApplicationGranularScope.where(application: application).delete_all
      end

      it_behaves_like 'does nothing'
    end

    context 'when the granular_oauth_tokens feature flag was disabled after the consent' do
      before do
        stub_feature_flags(granular_oauth_tokens: false)
      end

      it_behaves_like 'does nothing'
    end
  end
end
