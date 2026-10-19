# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplications::RevokeNonGranularTokensWorker, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application) }

  let!(:legacy_token) { create(:oauth_access_token, resource_owner: user, application: application, scopes: 'api') }
  let!(:granular_token) { create(:oauth_access_token, :granular, resource_owner: user, application: application) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [application.id, user.id] }

      it 'revokes the legacy tokens and keeps the granular ones', :aggregate_failures do
        perform_idempotent_work

        expect(legacy_token.reload).to be_revoked
        expect(granular_token.reload).not_to be_revoked
      end
    end

    context 'when the user no longer exists' do
      it 'does nothing' do
        expect(Authn::OauthApplication).not_to receive(:revoke_non_granular_tokens_and_grants_for)

        described_class.new.perform(application.id, non_existing_record_id)
      end
    end
  end
end
