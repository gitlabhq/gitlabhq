# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::RateLimiter do
  let(:key) { :some_key }
  let(:scope) { [:some, :scope] }
  let(:request) { instance_double('Rack::Request') }
  let(:user) { build_stubbed(:user) }
  let(:ip) { '0.0.0.0' }

  let(:api_class) do
    Class.new do
      include API::Helpers::RateLimiter

      attr_reader :request, :current_user, :ip_address

      def initialize(request, current_user, ip_address:)
        @request = request
        @current_user = current_user
        @ip_address = ip_address
      end

      def too_many_requests!(message, retry_after:); end
    end
  end

  let(:rate_limiter) { api_class.new(request, user, ip_address: ip) }

  before do
    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
    allow(::Gitlab::ApplicationRateLimiter).to receive(:log_request)
  end

  shared_examples 'checks rate limit by scope' do
    it 'calls ApplicationRateLimiter#throttled_request? with the right arguments' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(request, user, key, scope: scope).and_return(false)
      expect(rate_limiter).not_to receive(:too_many_requests!)

      rate_limit
    end

    it 'calls too_many_requests! with correct retry_after when throttled' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(key).and_return(5.minutes)
      expect(rate_limiter).to receive(:too_many_requests!).with(
        { error: _('This endpoint has been requested too many times. Try again later.') },
        retry_after: 5.minutes
      )

      rate_limit
    end

    context 'when the bypass header is set' do
      before do
        allow(Gitlab::Throttle).to receive(:bypass_header).and_return('SOME_HEADER')
      end

      it 'skips rate limit if set to "1"' do
        allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('1')

        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)
        expect(rate_limiter).not_to receive(:too_many_requests!)

        rate_limit
      end

      it 'does not skip rate limit if set to something else than "1"' do
        allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('0')

        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)

        rate_limit
      end
    end
  end

  describe '#check_rate_limit!' do
    subject(:rate_limit) { rate_limiter.check_rate_limit!(key, scope: scope) }

    it_behaves_like 'checks rate limit by scope'
  end

  describe '#check_rate_limit_by_user_or_ip!' do
    subject(:rate_limit) { rate_limiter.check_rate_limit_by_user_or_ip!(key) }

    context 'when current user is present' do
      let(:scope) { user }

      it_behaves_like 'checks rate limit by scope'
    end

    context 'when current user is not present rate limits by IP address' do
      let(:scope) { ip }
      let(:user) { nil }

      it_behaves_like 'checks rate limit by scope'
    end
  end

  describe '#mark_throttle!' do
    it 'calls ApplicationRateLimiter#throttle?' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(false)

      rate_limiter.mark_throttle!(key, scope: scope)
    end
  end

  describe 'Retry-After header functionality' do
    let(:args) { {} }

    subject(:rate_limit) { rate_limiter.check_rate_limit!(key, scope: scope, **args) }

    context 'when rate limit is triggered' do
      it 'passes the interval value from ApplicationRateLimiter to too_many_requests!' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
        expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(key).and_return(2.minutes)
        expect(rate_limiter).to receive(:too_many_requests!).with(
          { error: _('This endpoint has been requested too many times. Try again later.') },
          retry_after: 2.minutes
        )

        rate_limit
      end

      context 'when custom interval is specified' do
        let(:args) { { interval: 10.minutes } }

        it 'uses custom interval' do
          expect(::Gitlab::ApplicationRateLimiter)
            .to receive(:throttled?).with(key, scope: scope, interval: args[:interval])
            .and_return(true)
          expect(::Gitlab::ApplicationRateLimiter).not_to receive(:interval)
          expect(rate_limiter).to receive(:too_many_requests!).with(
            { error: _('This endpoint has been requested too many times. Try again later.') },
            retry_after: args[:interval]
          )

          rate_limit
        end
      end

      context 'with real ApplicationRateLimiter intervals' do
        let(:key) { :search_rate_limit }

        it 'uses the configured interval from rate_limits configuration' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
          expect(rate_limiter).to receive(:too_many_requests!).with(
            { error: _('This endpoint has been requested too many times. Try again later.') },
            retry_after: 1.minute
          )

          rate_limit
        end
      end

      context 'with custom rate limit key' do
        let(:key) { :projects_api }

        it 'uses the configured interval for projects_api' do
          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
          expect(rate_limiter).to receive(:too_many_requests!).with(
            { error: _('This endpoint has been requested too many times. Try again later.') },
            retry_after: 10.minutes
          )

          rate_limit
        end
      end
    end

    context 'when testing different interval values' do
      it 'handles different interval values correctly' do
        test_cases = [
          { interval: 30.seconds, expected_seconds: 30 },
          { interval: 5.minutes, expected_seconds: 300 },
          { interval: 1.hour, expected_seconds: 3600 },
          { interval: 1.day, expected_seconds: 86400 }
        ]

        test_cases.each do |test_case|
          # Create a fresh rate_limiter instance for each test case
          rate_limiter_instance = api_class.new(request, user, ip_address: ip)

          expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
          expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(key).and_return(test_case[:interval])
          expect(rate_limiter_instance).to receive(:too_many_requests!).with(
            { error: _('This endpoint has been requested too many times. Try again later.') },
            retry_after: test_case[:expected_seconds]
          )

          rate_limiter_instance.check_rate_limit!(key, scope: scope)
        end
      end
    end

    context 'when rate limit is not triggered' do
      it 'does not call too_many_requests!' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(false)
        expect(rate_limiter).not_to receive(:too_many_requests!)

        rate_limit
      end
    end
  end

  describe 'block execution behavior' do
    let(:custom_logic_executed) { [] }
    let(:args) { { scope: scope } }

    subject(:check_rate_limit) do
      rate_limiter.check_rate_limit!(key, **args) do
        custom_logic_executed << :block_executed
      end
    end

    it 'executes both the block and standard response' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(key).and_return(5.minutes)
      expect(rate_limiter).to receive(:too_many_requests!).with(
        { error: _('This endpoint has been requested too many times. Try again later.') },
        retry_after: 5.minutes
      )

      check_rate_limit

      expect(custom_logic_executed).to contain_exactly(:block_executed)
    end

    context 'when custom interval is provided' do
      let(:args) { { scope: scope, interval: 10.minutes } }

      it 'uses custom interval' do
        expect(::Gitlab::ApplicationRateLimiter)
          .to receive(:throttled?).with(key, **args).and_return(true)
        expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, :"#{key}_request_limit", user)
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:interval)
        expect(rate_limiter).to receive(:too_many_requests!).with(
          { error: _('This endpoint has been requested too many times. Try again later.') },
          retry_after: 10.minutes
        )

        check_rate_limit

        expect(custom_logic_executed).to contain_exactly(:block_executed)
      end
    end

    describe 'when a custom message is provided' do
      let(:custom_message) { 'Custom API rate limit message' }
      let(:args) { { scope: scope, message: custom_message } }

      subject(:check_rate_limit) do
        rate_limiter.check_rate_limit!(key, **args)
      end

      it 'uses the custom message in the response' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
        expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, :"#{key}_request_limit", user)
        expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(key).and_return(5.minutes)

        expect(rate_limiter).to receive(:too_many_requests!).with(
          { error: custom_message },
          retry_after: 5.minutes
        )

        check_rate_limit
      end
    end
  end
end
