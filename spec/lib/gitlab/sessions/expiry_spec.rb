# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sessions::Expiry, :freeze_time, feature_category: :system_access do
  include LoginHelpers

  let(:session_expire_delay) { 30 }
  let(:boot_session_expire_delay) { 45 }
  let(:last_write_at) { Time.current.utc.to_i }
  let(:signed_in_at) { Time.current.utc.to_i }
  let(:saml_enabled) { true }
  let(:session) do
    {
      'warden.user.user.session' => {
        Gitlab::Auth::SessionExpireFromInitEnforcer::SESSION_NAMESPACE => {
          'signed_in_at' => signed_in_at
        }
      }
    }
  end

  before do
    # The activity path reads the boot-cached Settings.gitlab (the source the Redis TTL is
    # built from); the init path reads the live application setting (matching the enforcer).
    stub_application_setting(session_expire_delay: session_expire_delay)
    allow(Gitlab.config.gitlab).to receive(:[]).and_call_original
    allow(Gitlab.config.gitlab).to receive(:[]).with('session_expire_delay').and_return(boot_session_expire_delay)

    # group SAML on its own must not open the gate, that is the gitlab.com case
    providers = saml_enabled ? [{ name: 'saml', args: {} }] : [{ name: 'group_saml' }]
    stub_omniauth_config(providers: providers)
  end

  describe '.expires_at' do
    subject(:expires_at) { described_class.expires_at(session, last_write_at: last_write_at) }

    context 'when SAML is configured' do
      it 'returns the deadline measured from the last recorded activity' do
        expect(expires_at).to eq(last_write_at + (boot_session_expire_delay * 60))
      end

      context 'when the session has no recorded activity' do
        let(:last_write_at) { nil }

        it { is_expected.to be_nil }
      end

      context 'when session_expire_modal_on_saml_instances is disabled' do
        before do
          stub_feature_flags(session_expire_modal_on_saml_instances: false)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when SAML is not configured' do
      let(:saml_enabled) { false }

      it { is_expected.to be_nil }
    end

    context 'when sessions expire from the time of sign-in' do
      let(:sign_in_deadline) { signed_in_at + (session_expire_delay * 60) }

      before do
        stub_application_setting(session_expire_from_init: true)
      end

      it 'returns the deadline measured from sign-in' do
        expect(expires_at).to eq(sign_in_deadline)
      end

      context 'when the last activity is later than sign-in' do
        let(:signed_in_at) { 10.minutes.ago.utc.to_i }

        it 'ignores the activity' do
          expect(expires_at).to eq(sign_in_deadline)
        end
      end

      context 'when the sign-in time is unknown' do
        let(:signed_in_at) { nil }

        it { is_expected.to be_nil }
      end

      context 'when SAML is not configured' do
        let(:saml_enabled) { false }

        it 'still returns the deadline, which does not depend on SAML' do
          expect(expires_at).to eq(sign_in_deadline)
        end
      end

      context 'when session_expire_modal_on_saml_instances is disabled' do
        before do
          stub_feature_flags(session_expire_modal_on_saml_instances: false)
        end

        it 'still returns the deadline, which does not depend on the flag' do
          expect(expires_at).to eq(sign_in_deadline)
        end
      end
    end
  end
end
