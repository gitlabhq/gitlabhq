# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplications::CleanupDynamicApplicationsWorker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    let_it_be(:dynamic_app) { create(:oauth_application, :dynamic) }
    let_it_be(:regular_app) { create(:oauth_application) }

    it 'deletes dynamic applications' do
      expect { worker.perform }.to change { Authn::OauthApplication.exists?(dynamic_app.id) }.from(true).to(false)
    end

    it 'does not destroy non-dynamic applications' do
      expect { worker.perform }.not_to change { Authn::OauthApplication.exists?(regular_app.id) }
    end

    it 'revokes all access tokens for the dynamic application before deleting it' do
      token = create(:oauth_access_token, application: dynamic_app)

      expect { worker.perform }.to change { token.reload.revoked_at }.from(nil)
    end

    it 'revokes all access grants for the dynamic application before deleting it' do
      grant = create(:oauth_access_grant, application: dynamic_app)

      expect { worker.perform }.to change { grant.reload.revoked_at }.from(nil)
    end

    it 'does not revoke tokens for non-dynamic applications' do
      token = create(:oauth_access_token, application: regular_app)

      expect { worker.perform }.not_to change { token.reload.revoked_at }
    end

    it 'does not revoke grants for non-dynamic applications' do
      grant = create(:oauth_access_grant, application: regular_app)

      expect { worker.perform }.not_to change { grant.reload.revoked_at }
    end

    context 'when the iam_svc_oauth feature flag is enabled' do
      before do
        stub_feature_flags(iam_svc_oauth: true)
      end

      it 'revokes consents for destroyed dynamic applications' do
        uid = dynamic_app.uid

        expect(Authn::OauthConsent).to receive(:revoke_authorized_for).with(client_id: [uid])

        worker.perform
      end

      it 'does not revoke consents for non-dynamic applications' do
        expect(Authn::OauthConsent).not_to receive(:revoke_authorized_for)
          .with(hash_including(client_id: array_including(regular_app.uid)))

        worker.perform
      end
    end

    context 'when the iam_svc_oauth feature flag is disabled' do
      before do
        stub_feature_flags(iam_svc_oauth: false)
      end

      it 'does not revoke consents' do
        expect(Authn::OauthConsent).not_to receive(:revoke_authorized_for)

        worker.perform
      end
    end

    context 'when the runtime limit is exceeded' do
      it 're-enqueues itself and stops processing' do
        runtime_limiter = instance_double(Gitlab::Metrics::RuntimeLimiter, over_time?: true)
        allow(Gitlab::Metrics::RuntimeLimiter).to receive(:new).and_return(runtime_limiter)

        expect(described_class).to receive(:perform_in).with(described_class::REQUEUE_DELAY)

        worker.perform
      end
    end
  end
end
