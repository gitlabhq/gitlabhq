# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::RateLimiter, 'Retry-After header integration', feature_category: :shared do
  include Rack::Test::Methods

  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:project, freeze: true) { create(:project) }

  let(:app) do
    Class.new(Grape::API::Instance) do
      helpers API::APIGuard::HelperMethods
      helpers API::Helpers
      helpers API::Helpers::RateLimiter
      format :json

      get 'test_rate_limit' do
        check_rate_limit!(:test_endpoint, scope: [current_user])
        { message: 'success' }
      end

      get 'test_rate_limit_with_custom_interval' do
        check_rate_limit!(:projects_api, scope: [current_user])
        { message: 'success' }
      end
    end
  end

  before do
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive_messages(current_user: user, authenticate_non_public?: false)
    end
  end

  describe 'Retry-After header in response' do
    context 'when rate limit is not triggered' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(false)
      end

      it 'does not include Retry-After header' do
        get 'test_rate_limit'

        expect(last_response.status).to eq(200)
        expect(last_response.headers).not_to have_key('Retry-After')
      end
    end

    context 'when rate limit is triggered' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(true)
      end

      it 'includes Retry-After header with custom interval (5 minutes)' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:interval).with(:test_endpoint).and_return(5.minutes)

        get 'test_rate_limit'

        expect(last_response.status).to eq(429)
        expect(last_response.headers['Retry-After']).to eq(300)
        expect(Gitlab::Json.parse(last_response.body).dig('message', 'error'))
          .to eq('This endpoint has been requested too many times. Try again later.')
      end

      it 'includes Retry-After header with configured interval for projects_api (10 minutes)' do
        get 'test_rate_limit_with_custom_interval'

        expect(last_response.status).to eq(429)
        expect(last_response.headers['Retry-After']).to eq(600)
        expect(Gitlab::Json.parse(last_response.body).dig('message', 'error'))
          .to eq('This endpoint has been requested too many times. Try again later.')
      end

      it 'handles different time intervals correctly' do
        test_cases = [
          { interval: 30.seconds, expected: 30 },
          { interval: 2.minutes, expected: 120 },
          { interval: 1.hour, expected: 3600 },
          { interval: 1.day, expected: 86400 }
        ]

        test_cases.each do |test_case|
          expect(::Gitlab::ApplicationRateLimiter)
            .to receive(:interval).with(:test_endpoint).and_return(test_case[:interval])

          get 'test_rate_limit'

          expect(last_response.status).to eq(429)
          expect(last_response.headers['Retry-After']).to eq(test_case[:expected])
        end
      end
    end

    context 'when bypass header is set' do
      before do
        allow(Gitlab::Throttle).to receive(:bypass_header).and_return('X-GitLab-Rate-Limit-Bypass')
      end

      it 'bypasses rate limit and does not include Retry-After header' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(false)

        header 'X-GitLab-Rate-Limit-Bypass', '1'
        get 'test_rate_limit'

        expect(last_response.status).to eq(200)
        expect(last_response.headers).not_to have_key('Retry-After')
      end
    end
  end

  describe 'rate limit configuration validation' do
    it 'uses correct intervals for common rate limit keys' do
      rate_limit_configs = {
        search_rate_limit: 1.minute,
        projects_api: 10.minutes,
        raw_blob: 1.minute,
        user_sign_in: 10.minutes
      }

      rate_limit_configs.each do |key, expected_interval|
        rate_limit_interval = Gitlab::ApplicationRateLimiter.interval(key)

        expect(rate_limit_interval).to eq(expected_interval.to_i),
          "Expected #{key} to have interval #{expected_interval.to_i} seconds, got #{rate_limit_interval}"
      end
    end
  end
end
