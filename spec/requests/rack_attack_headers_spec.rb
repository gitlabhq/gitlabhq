# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack Attack Headers', :use_clean_rails_memory_store_caching,
  feature_category: :rate_limiting do
  include RackAttackSpecHelpers
  include WorkhorseHelpers

  let(:settings) { Gitlab::CurrentSettings.current_application_settings }

  # Set high rate limits to avoid actually throttling requests
  let(:settings_to_set) do
    {
      throttle_unauthenticated_api_enabled: true,
      throttle_unauthenticated_api_requests_per_period: 100,
      throttle_unauthenticated_api_period_in_seconds: 60,
      throttle_authenticated_api_enabled: true,
      throttle_authenticated_api_requests_per_period: 100,
      throttle_authenticated_api_period_in_seconds: 60
    }
  end

  include_context 'rack attack cache store'

  before do
    settings.update!(settings_to_set)
    stub_feature_flags(rate_limiting_headers_for_unthrottled_requests: true)
  end

  describe 'rate limit headers for unthrottled requests' do
    context 'with unauthenticated API requests' do
      let(:url) { '/api/v4/projects' }

      it 'includes rate limit headers on successful requests' do
        get url

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers).to include('RateLimit-Name')
        expect(response.headers).to include('RateLimit-Limit')
        expect(response.headers).to include('RateLimit-Observed')
        expect(response.headers).to include('RateLimit-Remaining')
        expect(response.headers).to include('RateLimit-Reset')
      end

      it 'does not include Retry-After header (only for 429 responses)' do
        get url

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers).not_to include('Retry-After')
        expect(response.headers).not_to include('RateLimit-ResetTime')
      end

      it 'shows correct throttle name' do
        get url

        expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
      end

      it 'tracks request count across multiple requests' do
        # First request
        get url
        expect(response).to have_gitlab_http_status(:ok)
        first_observed = response.headers['RateLimit-Observed'].to_i
        first_remaining = response.headers['RateLimit-Remaining'].to_i

        # Second request
        get url
        expect(response).to have_gitlab_http_status(:ok)
        second_observed = response.headers['RateLimit-Observed'].to_i
        second_remaining = response.headers['RateLimit-Remaining'].to_i

        expect(second_observed).to eq(first_observed + 1)
        expect(second_remaining).to eq(first_remaining - 1)
      end

      it 'includes all header values as strings' do
        get url

        expect(response.headers['RateLimit-Name']).to be_a(String)
        expect(response.headers['RateLimit-Limit']).to be_a(String)
        expect(response.headers['RateLimit-Observed']).to be_a(String)
        expect(response.headers['RateLimit-Remaining']).to be_a(String)
        expect(response.headers['RateLimit-Reset']).to be_a(String)
      end
    end

    context 'with authenticated API requests' do
      let_it_be(:user) { create(:user) }
      let_it_be(:token) { create(:personal_access_token, user: user) }
      let(:url) { "/api/v4/projects?private_token=#{token.token}" }

      it 'includes rate limit headers for authenticated requests' do
        get url

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['RateLimit-Name']).to eq('throttle_authenticated_api')
        expect(response.headers).to include('RateLimit-Limit')
        expect(response.headers).to include('RateLimit-Remaining')
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(rate_limiting_headers_for_unthrottled_requests: false)
      end

      it 'does not include rate limit headers' do
        get '/api/v4/projects'

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers).not_to include('RateLimit-Name')
        expect(response.headers).not_to include('RateLimit-Limit')
        expect(response.headers).not_to include('RateLimit-Observed')
        expect(response.headers).not_to include('RateLimit-Remaining')
        expect(response.headers).not_to include('RateLimit-Reset')
      end
    end

    context 'when request is throttled (429)' do
      let(:settings_to_set) do
        {
          throttle_unauthenticated_api_enabled: true,
          throttle_unauthenticated_api_requests_per_period: 1,
          throttle_unauthenticated_api_period_in_seconds: 60
        }
      end

      it 'includes rate limit headers with Retry-After' do
        # Exhaust the rate limit
        2.times { get '/api/v4/projects' }

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
        expect(response.headers).to include('Retry-After')
        expect(response.headers).to include('RateLimit-ResetTime')
        expect(response.headers['RateLimit-Remaining']).to eq('0')
      end
    end

    context 'with multiple throttles active' do
      let(:settings_to_set) do
        {
          throttle_unauthenticated_api_enabled: true,
          throttle_unauthenticated_api_requests_per_period: 50,
          throttle_unauthenticated_api_period_in_seconds: 60,
          throttle_unauthenticated_enabled: true,
          throttle_unauthenticated_requests_per_period: 100,
          throttle_unauthenticated_period_in_seconds: 60
        }
      end

      it 'returns headers for the most restrictive throttle' do
        # Make several API requests to increase observed count
        5.times { get '/api/v4/projects' }

        expect(response).to have_gitlab_http_status(:ok)
        # API throttle (50 limit) is more restrictive than web throttle (100 limit)
        expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
        expect(response.headers['RateLimit-Limit']).to eq('50')

        observed = response.headers['RateLimit-Observed'].to_i
        remaining = response.headers['RateLimit-Remaining'].to_i

        expect(observed).to eq(5)
        expect(remaining).to eq(45)
      end
    end

    context 'with different endpoint types' do
      it 'includes headers for API 404 responses' do
        get '/api/v4/nonexistent'

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.headers).to include('RateLimit-Name')
        expect(response.headers).to include('RateLimit-Remaining')
      end

      it 'includes headers for API error responses' do
        get '/api/v4/projects/99999999'

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
        expect(response.headers).to include('RateLimit-Observed')
      end
    end

    context 'with normalized rate limits' do
      let(:settings_to_set) do
        {
          throttle_unauthenticated_api_enabled: true,
          throttle_unauthenticated_api_requests_per_period: 200,
          throttle_unauthenticated_api_period_in_seconds: 120 # 2 minutes
        }
      end

      it 'normalizes limit to 60-second window' do
        get '/api/v4/projects'

        expect(response).to have_gitlab_http_status(:ok)
        # 200 requests per 120 seconds = 100 requests per 60 seconds
        expect(response.headers['RateLimit-Limit']).to eq('100')
      end
    end

    context 'with valid RateLimit-Reset header' do
      it 'includes a valid Unix timestamp' do
        get '/api/v4/projects'

        reset_time = response.headers['RateLimit-Reset'].to_i
        expect(reset_time).to be > Time.now.to_i
        expect(reset_time).to be < (Time.now + 1.hour).to_i
      end
    end
  end
end
