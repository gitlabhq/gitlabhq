# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::ValidateTokenService, :clean_gitlab_redis_rate_limiting, feature_category: :system_access do
  let(:email) { build_stubbed(:user).email }
  let(:token) { nil }

  describe '#execute' do
    shared_examples 'successful token validation' do
      it 'returns success status' do
        expect(service.execute).to eq(status: :success)
      end
    end

    shared_examples 'common token validation failures' do
      it 'returns failure when rate limited' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification, scope: encrypted_token).and_return(true)

        result = service.execute

        expect(result).to eq(
          status: :failure,
          reason: :rate_limited,
          message: format(s_("IdentityVerification|You've reached the maximum amount of tries. "\
                           'Wait %{interval} or send a new code and try again.'), interval: '10 minutes')
        )
      end

      it 'returns failure when token is expired' do
        allow(service).to receive(:expired_token?).and_return(true)

        result = service.execute

        expect(result).to eq(
          status: :failure,
          reason: :expired,
          message: s_('IdentityVerification|The code has expired. Send a new code and try again.')
        )
      end

      context 'when token is invalid' do
        let(:provided_token) { '123456' }

        it 'returns failure' do
          result = service.execute

          expect(result).to eq(
            status: :failure,
            reason: :invalid,
            message: s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')
          )
        end
      end

      context 'when encrypted token is nil and blank token provided' do
        let(:encrypted_token) { nil }
        let(:provided_token) { '' }

        it 'returns failure' do
          result = service.execute

          expect(result).to eq(
            status: :failure,
            reason: :invalid,
            message: s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')
          )
        end
      end
    end

    context 'when validating unlock_token' do
      let(:token) { '001122' }
      let(:encrypted_token) { Devise.token_generator.digest(User, email, token) }
      let(:user) { build(:user, email: email, unlock_token: encrypted_token, locked_at: 1.second.ago) }
      let(:provided_token) { token }
      let(:service) { described_class.new(attr: :unlock_token, user: user, token: provided_token) }

      include_examples 'successful token validation'
      include_examples 'common token validation failures'
    end

    context 'when validating confirmation_token' do
      let(:token) { '001122' }
      let(:encrypted_token) { Devise.token_generator.digest(User, email, token) }
      let(:user) { build(:user, email: email, confirmation_token: encrypted_token, confirmation_sent_at: 1.second.ago) }
      let(:provided_token) { token }
      let(:service) { described_class.new(attr: :confirmation_token, user: user, token: provided_token) }

      include_examples 'successful token validation'
      include_examples 'common token validation failures'
    end

    context 'with an invalid attr' do
      let(:user) { build(:user) }
      let(:service) { described_class.new(attr: :username, user: user, token: '001122') }

      it 'raises an error' do
        expect { service.execute }.to raise_error(ArgumentError, 'Invalid attribute')
      end
    end
  end

  describe '#expired_token?' do
    shared_examples 'token expiry logic' do |timestamp_method|
      it 'returns false when token is within valid timeframe' do
        allow(user).to receive(timestamp_method).and_return(59.minutes.ago)

        expect(service.expired_token?).to be false
      end

      it 'returns true when token is beyond valid timeframe' do
        allow(user).to receive(timestamp_method).and_return(61.minutes.ago)

        expect(service.expired_token?).to be true
      end

      it 'returns true when timestamp is nil' do
        allow(user).to receive(timestamp_method).and_return(nil)

        expect(service.expired_token?).to be true
      end

      it "uses #{timestamp_method} timestamp for expiry calculation" do
        allow(user).to receive(timestamp_method).and_return(30.minutes.ago)

        service.expired_token?

        expect(user).to have_received(timestamp_method)
      end
    end

    context 'when attribute is unlock_token' do
      let(:user) { build(:user) }
      let(:service) { described_class.new(attr: :unlock_token, user: user, token: token) }

      include_examples 'token expiry logic', :locked_at
    end

    context 'when attribute is confirmation_token' do
      let(:user) { build(:user) }
      let(:service) { described_class.new(attr: :confirmation_token, user: user, token: token) }

      include_examples 'token expiry logic', :confirmation_sent_at
    end
  end
end
