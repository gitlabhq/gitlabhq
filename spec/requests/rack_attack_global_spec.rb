# frozen_string_literal: true

require 'spec_helper'

describe 'Rack Attack global throttles' do
  include RackAttackSpecHelpers

  let(:settings) { Gitlab::CurrentSettings.current_application_settings }

  # Start with really high limits and override them with low limits to ensure
  # the right settings are being exercised
  let(:settings_to_set) do
    {
      throttle_unauthenticated_requests_per_period: 100,
      throttle_unauthenticated_period_in_seconds: 1,
      throttle_authenticated_api_requests_per_period: 100,
      throttle_authenticated_api_period_in_seconds: 1,
      throttle_authenticated_web_requests_per_period: 100,
      throttle_authenticated_web_period_in_seconds: 1,
      throttle_authenticated_protected_paths_request_per_period: 100,
      throttle_authenticated_protected_paths_in_seconds: 1
    }
  end

  let(:request_method) { 'GET' }
  let(:requests_per_period) { 1 }
  let(:period_in_seconds) { 10000 }
  let(:period) { period_in_seconds.seconds }

  include_context 'rack attack cache store'

  describe 'unauthenticated requests' do
    let(:url_that_does_not_require_authentication) { '/users/sign_in' }
    let(:url_api_internal) { '/api/v4/internal/check' }

    before do
      # Disabling protected paths throttle, otherwise requests to
      # '/users/sign_in' are caught by this throttle.
      settings_to_set[:throttle_protected_paths_enabled] = false

      # Set low limits
      settings_to_set[:throttle_unauthenticated_requests_per_period] = requests_per_period
      settings_to_set[:throttle_unauthenticated_period_in_seconds] = period_in_seconds
    end

    context 'when the throttle is enabled' do
      before do
        settings_to_set[:throttle_unauthenticated_enabled] = true
        stub_application_setting(settings_to_set)
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_http_status 200
        end

        # the last straw
        expect_rejection { get url_that_does_not_require_authentication }
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_http_status 200
        end

        expect_rejection { get url_that_does_not_require_authentication }

        Timecop.travel(period.from_now) do
          requests_per_period.times do
            get url_that_does_not_require_authentication
            expect(response).to have_http_status 200
          end

          expect_rejection { get url_that_does_not_require_authentication }
        end
      end

      it 'counts requests from different IPs separately' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_http_status 200
        end

        expect_next_instance_of(Rack::Attack::Request) do |instance|
          expect(instance).to receive(:ip).at_least(:once).and_return('1.2.3.4')
        end

        # would be over limit for the same IP
        get url_that_does_not_require_authentication
        expect(response).to have_http_status 200
      end

      context 'when the request is to the api internal endpoints' do
        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            get url_api_internal, params: { secret_token: Gitlab::Shell.secret_token }
            expect(response).to have_http_status 200
          end
        end
      end

      context 'when the request is authenticated by a runner token' do
        let(:request_jobs_url) { '/api/v4/jobs/request' }
        let(:runner) { create(:ci_runner) }

        it 'does not cont as unauthenticated' do
          (1 + requests_per_period).times do
            post request_jobs_url, params: { token: runner.token }
            expect(response).to have_http_status 204
          end
        end
      end

      it 'logs RackAttack info into structured logs' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_http_status 200
        end

        arguments = {
          message: 'Rack_Attack',
          env: :throttle,
          remote_ip: '127.0.0.1',
          request_method: 'GET',
          path: '/users/sign_in'
        }

        expect(Gitlab::AuthLogger).to receive(:error).with(arguments)

        get url_that_does_not_require_authentication
      end
    end

    context 'when the throttle is disabled' do
      before do
        settings_to_set[:throttle_unauthenticated_enabled] = false
        stub_application_setting(settings_to_set)
      end

      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get url_that_does_not_require_authentication
          expect(response).to have_http_status 200
        end
      end
    end
  end

  describe 'API requests authenticated with personal access token', :api do
    let(:user) { create(:user) }
    let(:token) { create(:personal_access_token, user: user) }
    let(:other_user) { create(:user) }
    let(:other_user_token) { create(:personal_access_token, user: other_user) }
    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }
    let(:api_partial_url) { '/todos' }

    context 'with the token in the query string' do
      let(:request_args) { [api(api_partial_url, personal_access_token: token)] }
      let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe 'API requests authenticated with OAuth token', :api do
    let(:user) { create(:user) }
    let(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }
    let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "api") }

    let(:other_user) { create(:user) }
    let(:other_user_application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: other_user) }
    let(:other_user_token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: other_user.id, scopes: "api") }

    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }
    let(:api_partial_url) { '/todos' }

    context 'with the token in the query string' do
      let(:request_args) { [api(api_partial_url, oauth_access_token: token)] }
      let(:other_user_request_args) { [api(api_partial_url, oauth_access_token: other_user_token)] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe '"web" (non-API) requests authenticated with RSS token' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:throttle_setting_prefix) { 'throttle_authenticated_web' }

    context 'with the token in the query string' do
      let(:request_args) { [rss_url(user), params: nil] }
      let(:other_user_request_args) { [rss_url(other_user), params: nil] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end
  end

  describe 'web requests authenticated with regular login' do
    let(:throttle_setting_prefix) { 'throttle_authenticated_web' }
    let(:user) { create(:user) }
    let(:url_that_requires_authentication) { '/dashboard/snippets' }

    it_behaves_like 'rate-limited web authenticated requests'
  end

  describe 'protected paths' do
    let(:request_method) { 'POST' }

    context 'unauthenticated requests' do
      let(:protected_path_that_does_not_require_authentication) do
        '/users/sign_in'
      end
      let(:post_params) { { user: { login: 'username', password: 'password' } } }

      before do
        settings_to_set[:throttle_protected_paths_requests_per_period] = requests_per_period # 1
        settings_to_set[:throttle_protected_paths_period_in_seconds] = period_in_seconds # 10_000
      end

      context 'when protected paths throttle is disabled' do
        before do
          settings_to_set[:throttle_protected_paths_enabled] = false
          stub_application_setting(settings_to_set)
        end

        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            post protected_path_that_does_not_require_authentication, params: post_params
            expect(response).to have_http_status 200
          end
        end
      end

      context 'when protected paths throttle is enabled' do
        before do
          settings_to_set[:throttle_protected_paths_enabled] = true
          stub_application_setting(settings_to_set)
        end

        it 'rejects requests over the rate limit' do
          requests_per_period.times do
            post protected_path_that_does_not_require_authentication, params: post_params
            expect(response).to have_http_status 200
          end

          expect_rejection { post protected_path_that_does_not_require_authentication, params: post_params }
        end

        context 'when Omnibus throttle should be used' do
          before do
            allow(Gitlab::Throttle)
              .to receive(:should_use_omnibus_protected_paths?).and_return(true)
          end

          it 'allows requests over the rate limit' do
            (1 + requests_per_period).times do
              post protected_path_that_does_not_require_authentication, params: post_params
              expect(response).to have_http_status 200
            end
          end
        end
      end
    end

    context 'API requests authenticated with personal access token', :api do
      let(:user) { create(:user) }
      let(:token) { create(:personal_access_token, user: user) }
      let(:other_user) { create(:user) }
      let(:other_user_token) { create(:personal_access_token, user: other_user) }
      let(:throttle_setting_prefix) { 'throttle_protected_paths' }
      let(:api_partial_url) { '/user/emails' }

      let(:protected_paths) do
        [
          '/api/v4/user/emails'
        ]
      end

      before do
        settings_to_set[:protected_paths] = protected_paths
        stub_application_setting(settings_to_set)
      end

      context 'with the token in the query string' do
        let(:request_args) { [api(api_partial_url, personal_access_token: token)] }
        let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token)] }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'with the token in the headers' do
        let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
        let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'when Omnibus throttle should be used' do
        let(:request_args) { [api(api_partial_url, personal_access_token: token)] }
        let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token)] }

        before do
          settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
          settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
          settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
          stub_application_setting(settings_to_set)

          allow(Gitlab::Throttle)
            .to receive(:should_use_omnibus_protected_paths?).and_return(true)
        end

        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            post(*request_args)
            expect(response).not_to have_http_status 429
          end
        end
      end
    end

    describe 'web requests authenticated with regular login' do
      let(:throttle_setting_prefix) { 'throttle_protected_paths' }
      let(:user) { create(:user) }
      let(:url_that_requires_authentication) { '/users/confirmation' }

      let(:protected_paths) do
        [
          url_that_requires_authentication
        ]
      end

      before do
        settings_to_set[:protected_paths] = protected_paths
        stub_application_setting(settings_to_set)
      end

      it_behaves_like 'rate-limited web authenticated requests'

      context 'when Omnibus throttle should be used' do
        before do
          settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
          settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
          settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
          stub_application_setting(settings_to_set)

          allow(Gitlab::Throttle)
            .to receive(:should_use_omnibus_protected_paths?).and_return(true)

          login_as(user)
        end

        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            post url_that_requires_authentication
            expect(response).not_to have_http_status 429
          end
        end
      end
    end
  end
end
