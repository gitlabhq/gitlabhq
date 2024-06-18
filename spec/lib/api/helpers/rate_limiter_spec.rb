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

      def render_api_error!(**args); end
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
      expect(rate_limiter).not_to receive(:render_api_error!)

      rate_limit
    end

    it 'renders api error and logs request if throttled' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)
      expect(rate_limiter).to receive(:render_api_error!).with({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)

      rate_limit
    end

    context 'when the bypass header is set' do
      before do
        allow(Gitlab::Throttle).to receive(:bypass_header).and_return('SOME_HEADER')
      end

      it 'skips rate limit if set to "1"' do
        allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('1')

        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)
        expect(rate_limiter).not_to receive(:render_api_error!)

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
end
