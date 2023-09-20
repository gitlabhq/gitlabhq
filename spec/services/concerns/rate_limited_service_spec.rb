# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RateLimitedService, feature_category: :rate_limiting do
  let(:key) { :issues_create }
  let(:scope) { [:container, :current_user] }
  let(:opts) { { scope: scope, users_allowlist: -> { [Users::Internal.support_bot.username] } } }
  let(:rate_limiter) { ::Gitlab::ApplicationRateLimiter }

  describe 'RateLimitedError' do
    subject { described_class::RateLimitedError.new(key: key, rate_limiter: rate_limiter) }

    describe '#headers' do
      it 'returns a Hash of HTTP headers' do
        # TODO: This will be fleshed out in https://gitlab.com/gitlab-org/gitlab/-/issues/342370
        expected_headers = {}

        expect(subject.headers).to eq(expected_headers)
      end
    end

    describe '#log_request' do
      it 'logs the request' do
        request = instance_double(Grape::Request)
        user = instance_double(User)

        expect(rate_limiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)

        subject.log_request(request, user)
      end
    end
  end

  describe 'RateLimiterScopedAndKeyed' do
    subject { described_class::RateLimiterScopedAndKeyed.new(key: key, opts: opts, rate_limiter: rate_limiter) }

    describe '#rate_limit!' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { create(:user) }

      let(:service) { instance_double(Issues::CreateService, container: project, current_user: current_user) }
      let(:evaluated_scope) { [project, current_user] }
      let(:evaluated_opts) { { scope: evaluated_scope, users_allowlist: %w[support-bot] } }

      context 'when rate limiting is not in effect' do
        let(:throttled) { false }

        it 'does not raise an exception' do
          expect(subject.rate_limit!(service)).to be_nil
        end
      end

      context 'when rate limiting is in effect' do
        before do
          allow(rate_limiter).to receive(:throttled?).and_return(true)
        end

        it 'raises a RateLimitedError exception' do
          expect { subject.rate_limit!(service) }.to raise_error(described_class::RateLimitedError, 'This endpoint has been requested too many times. Try again later.')
        end
      end
    end
  end

  describe '#execute_without_rate_limiting' do
    let(:rate_limiter_scoped_and_keyed) { instance_double(RateLimitedService::RateLimiterScopedAndKeyed) }
    let(:subject) do
      local_key = key
      local_opts = opts

      Class.new do
        prepend RateLimitedService

        rate_limit key: local_key, opts: local_opts

        def execute(*args, **kwargs)
          'main logic here'
        end
      end.new
    end

    before do
      allow(RateLimitedService::RateLimiterScopedAndKeyed).to receive(:new).with(key: key, opts: opts, rate_limiter: rate_limiter).and_return(rate_limiter_scoped_and_keyed)
    end

    context 'bypasses rate limiting' do
      it 'calls super' do
        expect(rate_limiter_scoped_and_keyed).not_to receive(:rate_limit!).with(subject)

        expect(subject.execute_without_rate_limiting).to eq('main logic here')
      end
    end
  end

  describe '#execute' do
    context 'when rate_limit has not been called' do
      let(:subject) { Class.new { prepend RateLimitedService }.new }

      it 'raises an RateLimitedNotSetupError exception' do
        expect { subject.execute }.to raise_error(described_class::RateLimitedNotSetupError)
      end
    end

    context 'when rate_limit has been called' do
      let(:rate_limiter_scoped_and_keyed) { instance_double(RateLimitedService::RateLimiterScopedAndKeyed) }
      let(:subject) do
        local_key = key
        local_opts = opts

        Class.new do
          prepend RateLimitedService

          rate_limit key: local_key, opts: local_opts

          def execute(*args, **kwargs)
            'main logic here'
          end
        end.new
      end

      before do
        allow(RateLimitedService::RateLimiterScopedAndKeyed).to receive(:new).with(key: key, opts: opts, rate_limiter: rate_limiter).and_return(rate_limiter_scoped_and_keyed)
      end

      context 'and applies rate limiting' do
        it 'raises an RateLimitedService::RateLimitedError exception' do
          expect(rate_limiter_scoped_and_keyed).to receive(:rate_limit!).with(subject).and_raise(RateLimitedService::RateLimitedError.new(key: key, rate_limiter: rate_limiter))

          expect { subject.execute }.to raise_error(RateLimitedService::RateLimitedError)
        end
      end

      context 'but does not apply rate limiting' do
        it 'calls super' do
          expect(rate_limiter_scoped_and_keyed).to receive(:rate_limit!).with(subject).and_return(nil)

          expect(subject.execute).to eq('main logic here')
        end
      end
    end
  end
end
