# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::SessionExpireFromInitEnforcer, feature_category: :system_access do
  let(:request_double) { instance_double(ActionDispatch::Request) }
  let(:session) { {} }
  let(:warden) { instance_double(Warden::Proxy, request: request_double, session: session) }
  let(:opts) do
    {
      scope: :user
    }
  end

  let(:instance) { described_class.new(warden, opts) }

  describe '.enabled?' do
    subject(:is_enabled) { described_class.enabled? }

    it { is_expected.to be(false) }

    context 'when session_expire_from_init setting is enabled' do
      before do
        stub_application_setting(session_expire_from_init: true)
      end

      it { is_expected.to be(true) }

      context 'and session_expire_from_init FF is disabled' do
        before do
          stub_feature_flags(session_expire_from_init: false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '.session_expires_at', :freeze_time do
    subject(:session_expires_at) { described_class.session_expires_at(session) }

    let(:signed_in_at) { nil }
    let(:session) do
      {
        'warden.user.user.session' => {
          described_class::SESSION_NAMESPACE => {
            'signed_in_at' => signed_in_at
          }
        }
      }
    end

    before do
      stub_application_setting(
        session_expire_from_init: true,
        session_expire_delay: 5
      )
    end

    it { is_expected.to eq(0) }

    context 'when session has sign in data set by enforcer' do
      let(:signed_in_at) { Time.current.utc.to_i - 4.minutes }

      it { is_expected.to eq(Time.current.utc.to_i + 1.minute) }
    end

    context 'when session has expired' do
      let(:signed_in_at) { Time.current.utc.to_i - 6.minutes }

      it { is_expected.to eq(Time.current.utc.to_i - 1.minute) }
    end

    context 'when session has no data' do
      let(:session) { {} }

      it { is_expected.to eq(0) }
    end
  end

  describe '#set_login_time', :freeze_time do
    subject(:set_login_time) { instance.set_login_time }

    before do
      stub_application_setting(
        session_expire_from_init: true,
        session_expire_delay: 5
      )
    end

    it 'sets signed_in_at session info' do
      set_login_time

      expect(session[described_class::SESSION_NAMESPACE]['signed_in_at']).to eq(Time.current.utc.to_i)
    end

    context 'when not enabled' do
      before do
        stub_application_setting(
          session_expire_from_init: false,
          session_expire_delay: 5
        )
      end

      it 'does not set signed_in_at session info' do
        set_login_time

        expect(session).to be_empty
      end
    end

    context 'when session_expire_from_init FF is disabled' do
      before do
        stub_feature_flags(session_expire_from_init: false)
      end

      it 'does not set signed_in_at session info' do
        set_login_time

        expect(session).to be_empty
      end
    end
  end

  describe '#enforce!', :freeze_time do
    subject(:enforce) { instance.enforce! }

    let(:devise_proxy) { instance_double(Devise::Hooks::Proxy) }

    before do
      stub_application_setting(
        session_expire_from_init: true,
        session_expire_delay: 5
      )
      allow(instance).to receive(:proxy).and_return(devise_proxy)
    end

    it 'does not throw' do
      expect { enforce }.not_to raise_error
    end

    context 'when session contains signed_in_at info' do
      let(:session) do
        {
          described_class::SESSION_NAMESPACE => {
            'signed_in_at' => Time.current.utc.to_i - 5.minutes - 1
          }
        }
      end

      it 'throws :warden error' do
        expect(devise_proxy).to receive(:sign_out)

        expect { enforce }.to throw_symbol(:warden)
      end

      context 'when session_expire_from_init FF is disabled' do
        before do
          stub_feature_flags(session_expire_from_init: false)
        end

        it 'does not throw :warden symbol' do
          expect(devise_proxy).not_to receive(:sign_out)

          expect { enforce }.not_to throw_symbol
        end
      end

      context 'when session has not expired yet' do
        let(:session) do
          {
            described_class::SESSION_NAMESPACE => {
              'signed_in_at' => Time.current.utc.to_i - 3.minutes
            }
          }
        end

        it 'does not throw :warden symbol' do
          expect(devise_proxy).not_to receive(:sign_out)

          expect { enforce }.not_to throw_symbol
        end
      end

      context 'when session_expire_from_init is not enabled' do
        before do
          stub_application_setting(
            session_expire_from_init: false,
            session_expire_delay: 5
          )
        end

        it 'does not throw :warden symbol' do
          expect(devise_proxy).not_to receive(:sign_out)

          expect { enforce }.not_to throw_symbol
        end
      end
    end
  end
end
