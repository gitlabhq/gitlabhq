# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack Attack global throttles', :use_clean_rails_memory_store_caching do
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
      throttle_authenticated_protected_paths_in_seconds: 1,
      throttle_unauthenticated_packages_api_requests_per_period: 100,
      throttle_unauthenticated_packages_api_period_in_seconds: 1,
      throttle_authenticated_packages_api_requests_per_period: 100,
      throttle_authenticated_packages_api_period_in_seconds: 1
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
          expect(response).to have_gitlab_http_status(:ok)
        end

        # the last straw
        expect_rejection { get url_that_does_not_require_authentication }
      end

      context 'with custom response text' do
        before do
          stub_application_setting(rate_limiting_response_text: 'Custom response')
        end

        it 'rejects requests over the rate limit' do
          # At first, allow requests under the rate limit.
          requests_per_period.times do
            get url_that_does_not_require_authentication
            expect(response).to have_gitlab_http_status(:ok)
          end

          # the last straw
          expect_rejection { get url_that_does_not_require_authentication }
          expect(response.body).to eq("Custom response\n")
        end
      end

      it 'allows requests after throttling and then waiting for the next period' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_gitlab_http_status(:ok)
        end

        expect_rejection { get url_that_does_not_require_authentication }

        travel_to(period.from_now) do
          requests_per_period.times do
            get url_that_does_not_require_authentication
            expect(response).to have_gitlab_http_status(:ok)
          end

          expect_rejection { get url_that_does_not_require_authentication }
        end
      end

      it 'counts requests from different IPs separately' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_gitlab_http_status(:ok)
        end

        expect_next_instance_of(Rack::Attack::Request) do |instance|
          expect(instance).to receive(:ip).at_least(:once).and_return('1.2.3.4')
        end

        # would be over limit for the same IP
        get url_that_does_not_require_authentication
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when the request is to the api internal endpoints' do
        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            get url_api_internal, params: { secret_token: Gitlab::Shell.secret_token }
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'when the request is authenticated by a runner token' do
        let(:request_jobs_url) { '/api/v4/jobs/request' }
        let(:runner) { create(:ci_runner) }

        it 'does not count as unauthenticated' do
          (1 + requests_per_period).times do
            post request_jobs_url, params: { token: runner.token }
            expect(response).to have_gitlab_http_status(:no_content)
          end
        end
      end

      context 'when the request is to a health endpoint' do
        let(:health_endpoint) { '/-/metrics' }

        it 'does not throttle the requests' do
          (1 + requests_per_period).times do
            get health_endpoint
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'when the request is to a container registry notification endpoint' do
        let(:secret_token) { 'secret_token' }
        let(:events) { [{ action: 'push' }] }
        let(:registry_endpoint) { '/api/v4/container_registry_event/events' }
        let(:registry_headers) { { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON } }

        before do
          allow(Gitlab.config.registry).to receive(:notification_secret) { secret_token }

          event = spy(:event)
          allow(::ContainerRegistry::Event).to receive(:new).and_return(event)
          allow(event).to receive(:supported?).and_return(true)
        end

        it 'does not throttle the requests' do
          (1 + requests_per_period).times do
            post registry_endpoint,
                 params: { events: events }.to_json,
                 headers: registry_headers.merge('Authorization' => secret_token)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      it 'logs RackAttack info into structured logs' do
        requests_per_period.times do
          get url_that_does_not_require_authentication
          expect(response).to have_gitlab_http_status(:ok)
        end

        arguments = a_hash_including({
          message: 'Rack_Attack',
          env: :throttle,
          remote_ip: '127.0.0.1',
          request_method: 'GET',
          path: '/users/sign_in',
          matched: 'throttle_unauthenticated'
        })

        expect(Gitlab::AuthLogger).to receive(:error).with(arguments)

        get url_that_does_not_require_authentication
      end

      it_behaves_like 'tracking when dry-run mode is set' do
        let(:throttle_name) { 'throttle_unauthenticated' }

        def do_request
          get url_that_does_not_require_authentication
        end
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
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'API requests authenticated with personal access token', :api do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:other_user_token) { create(:personal_access_token, user: other_user) }

    let(:throttle_setting_prefix) { 'throttle_authenticated_api' }
    let(:api_partial_url) { '/todos' }

    context 'with the token in the query string' do
      let(:request_args) { [api(api_partial_url, personal_access_token: token), {}] }
      let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token), {}] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the OAuth headers' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in basic auth' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, basic_auth_headers(user, token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, basic_auth_headers(other_user, other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with a read_api scope' do
      before do
        token.update!(scopes: ['read_api'])
        other_user_token.update!(scopes: ['read_api'])
      end

      context 'with the token in the headers' do
        let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
        let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'with the token in the OAuth headers' do
        let(:request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(token)) }
        let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(other_user_token)) }

        it_behaves_like 'rate-limited token-authenticated requests'
      end
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
      let(:request_args) { [api(api_partial_url, oauth_access_token: token), {}] }
      let(:other_user_request_args) { [api(api_partial_url, oauth_access_token: other_user_token), {}] }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with the token in the headers' do
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(other_user_token)) }

      it_behaves_like 'rate-limited token-authenticated requests'
    end

    context 'with a read_api scope' do
      let(:read_token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "read_api") }
      let(:other_user_read_token) { Doorkeeper::AccessToken.create!(application_id: other_user_application.id, resource_owner_id: other_user.id, scopes: "read_api") }
      let(:request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(read_token)) }
      let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, oauth_token_headers(other_user_read_token)) }

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

      def do_request
        post protected_path_that_does_not_require_authentication, params: post_params
      end

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
            do_request
            expect(response).to have_gitlab_http_status(:ok)
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
            do_request
            expect(response).to have_gitlab_http_status(:ok)
          end

          expect_rejection { post protected_path_that_does_not_require_authentication, params: post_params }
        end

        it_behaves_like 'tracking when dry-run mode is set' do
          let(:throttle_name) { 'throttle_unauthenticated_protected_paths' }
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
        let(:request_args) { [api(api_partial_url, personal_access_token: token), {}] }
        let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token), {}] }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'with the token in the headers' do
        let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
        let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

        it_behaves_like 'rate-limited token-authenticated requests'
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
    end
  end

  describe 'Packages API' do
    let(:request_method) { 'GET' }

    context 'unauthenticated' do
      let_it_be(:project) { create(:project, :public) }

      let(:throttle_setting_prefix) { 'throttle_unauthenticated_packages_api' }
      let(:packages_path_that_does_not_require_authentication) { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" }

      def do_request
        get packages_path_that_does_not_require_authentication
      end

      before do
        settings_to_set[:throttle_unauthenticated_packages_api_requests_per_period] = requests_per_period
        settings_to_set[:throttle_unauthenticated_packages_api_period_in_seconds] = period_in_seconds
      end

      context 'when unauthenticated packages api throttle is disabled' do
        before do
          settings_to_set[:throttle_unauthenticated_packages_api_enabled] = false
          stub_application_setting(settings_to_set)
        end

        it 'allows requests over the rate limit' do
          (1 + requests_per_period).times do
            do_request
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when unauthenticated api throttle is enabled' do
          before do
            settings_to_set[:throttle_unauthenticated_requests_per_period] = requests_per_period
            settings_to_set[:throttle_unauthenticated_period_in_seconds] = period_in_seconds
            settings_to_set[:throttle_unauthenticated_enabled] = true
            stub_application_setting(settings_to_set)
          end

          it 'rejects requests over the unauthenticated api rate limit' do
            requests_per_period.times do
              do_request
              expect(response).to have_gitlab_http_status(:ok)
            end

            expect_rejection { do_request }
          end
        end
      end

      context 'when unauthenticated packages api throttle is enabled' do
        before do
          settings_to_set[:throttle_unauthenticated_packages_api_requests_per_period] = requests_per_period # 1
          settings_to_set[:throttle_unauthenticated_packages_api_period_in_seconds] = period_in_seconds # 10_000
          settings_to_set[:throttle_unauthenticated_packages_api_enabled] = true
          stub_application_setting(settings_to_set)
        end

        it 'rejects requests over the rate limit' do
          requests_per_period.times do
            do_request
            expect(response).to have_gitlab_http_status(:ok)
          end

          expect_rejection { do_request }
        end

        context 'when unauthenticated api throttle is lower' do
          before do
            settings_to_set[:throttle_unauthenticated_requests_per_period] = 0
            settings_to_set[:throttle_unauthenticated_period_in_seconds] = period_in_seconds
            settings_to_set[:throttle_unauthenticated_enabled] = true
            stub_application_setting(settings_to_set)
          end

          it 'ignores unauthenticated api throttle' do
            requests_per_period.times do
              do_request
              expect(response).to have_gitlab_http_status(:ok)
            end

            expect_rejection { do_request }
          end
        end

        it_behaves_like 'tracking when dry-run mode is set' do
          let(:throttle_name) { 'throttle_unauthenticated_packages_api' }
        end
      end
    end

    context 'authenticated', :api do
      let_it_be(:project) { create(:project, :internal) }
      let_it_be(:user) { create(:user) }
      let_it_be(:token) { create(:personal_access_token, user: user) }
      let_it_be(:other_user) { create(:user) }
      let_it_be(:other_user_token) { create(:personal_access_token, user: other_user) }

      let(:throttle_setting_prefix) { 'throttle_authenticated_packages_api' }
      let(:api_partial_url) { "/projects/#{project.id}/packages/conan/v1/ping" }

      before do
        stub_application_setting(settings_to_set)
      end

      context 'with the token in the query string' do
        let(:request_args) { [api(api_partial_url, personal_access_token: token), {}] }
        let(:other_user_request_args) { [api(api_partial_url, personal_access_token: other_user_token), {}] }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'with the token in the headers' do
        let(:request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(token)) }
        let(:other_user_request_args) { api_get_args_with_token_headers(api_partial_url, personal_access_token_headers(other_user_token)) }

        it_behaves_like 'rate-limited token-authenticated requests'
      end

      context 'precedence over authenticated api throttle' do
        before do
          settings_to_set[:throttle_authenticated_packages_api_requests_per_period] = requests_per_period
          settings_to_set[:throttle_authenticated_packages_api_period_in_seconds] = period_in_seconds
        end

        def do_request
          get api(api_partial_url, personal_access_token: token)
        end

        context 'when authenticated packages api throttle is enabled' do
          before do
            settings_to_set[:throttle_authenticated_packages_api_enabled] = true
          end

          context 'when authenticated api throttle is lower' do
            before do
              settings_to_set[:throttle_authenticated_api_requests_per_period] = 0
              settings_to_set[:throttle_authenticated_api_period_in_seconds] = period_in_seconds
              settings_to_set[:throttle_authenticated_api_enabled] = true
              stub_application_setting(settings_to_set)
            end

            it 'ignores authenticated api throttle' do
              requests_per_period.times do
                do_request
                expect(response).to have_gitlab_http_status(:ok)
              end

              expect_rejection { do_request }
            end
          end
        end

        context 'when authenticated packages api throttle is disabled' do
          before do
            settings_to_set[:throttle_authenticated_packages_api_enabled] = false
          end

          context 'when authenticated api throttle is enabled' do
            before do
              settings_to_set[:throttle_authenticated_api_requests_per_period] = requests_per_period
              settings_to_set[:throttle_authenticated_api_period_in_seconds] = period_in_seconds
              settings_to_set[:throttle_authenticated_api_enabled] = true
              stub_application_setting(settings_to_set)
            end

            it 'rejects requests over the authenticated api rate limit' do
              requests_per_period.times do
                do_request
                expect(response).to have_gitlab_http_status(:ok)
              end

              expect_rejection { do_request }
            end
          end
        end
      end
    end
  end

  describe 'throttle bypass header' do
    let(:headers) { {} }
    let(:bypass_header) { 'gitlab-bypass-rate-limiting' }

    def do_request
      get '/users/sign_in', headers: headers
    end

    before do
      # Disabling protected paths throttle, otherwise requests to
      # '/users/sign_in' are caught by this throttle.
      settings_to_set[:throttle_protected_paths_enabled] = false

      # Set low limits
      settings_to_set[:throttle_unauthenticated_requests_per_period] = requests_per_period
      settings_to_set[:throttle_unauthenticated_period_in_seconds] = period_in_seconds

      stub_env('GITLAB_THROTTLE_BYPASS_HEADER', bypass_header)
      settings_to_set[:throttle_unauthenticated_enabled] = true

      stub_application_setting(settings_to_set)
    end

    shared_examples 'reject requests over the rate limit' do
      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          do_request
          expect(response).to have_gitlab_http_status(:ok)
        end

        # the last straw
        expect_rejection { do_request }
      end
    end

    context 'without the bypass header set' do
      it_behaves_like 'reject requests over the rate limit'
    end

    context 'with bypass header set to 1' do
      let(:headers) { { bypass_header => '1' } }

      it 'does not throttle' do
        (1 + requests_per_period).times do
          do_request
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with bypass header set to some other value' do
      let(:headers) { { bypass_header => 'some other value' } }

      it_behaves_like 'reject requests over the rate limit'
    end
  end

  describe 'Gitlab::RackAttack::Request#unauthenticated?' do
    let_it_be(:url) { "/api/v4/projects" }
    let_it_be(:user) { create(:user) }

    def expect_unauthenticated_request
      expect_next_instance_of(Rack::Attack::Request) do |instance|
        expect(instance.unauthenticated?).to be true
      end
    end

    def expect_authenticated_request
      expect_next_instance_of(Rack::Attack::Request) do |instance|
        expect(instance.unauthenticated?).to be false
      end
    end

    before do
      settings_to_set[:throttle_unauthenticated_enabled] = true
      stub_application_setting(settings_to_set)
    end

    context 'without authentication' do
      it 'request is unauthenticated' do
        expect_unauthenticated_request

        get url
      end
    end

    context 'authenticated by a runner token' do
      let_it_be(:runner) { create(:ci_runner) }

      it 'request is authenticated' do
        expect_authenticated_request

        get url, params: { token: runner.token }
      end
    end

    context 'authenticated with personal access token' do
      let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

      it 'request is authenticated by token in query string' do
        expect_authenticated_request

        get url, params: { private_token: personal_access_token.token }
      end

      it 'request is authenticated by token in the headers' do
        expect_authenticated_request

        get url, headers: personal_access_token_headers(personal_access_token)
      end

      it 'request is authenticated by token in the OAuth headers' do
        expect_authenticated_request

        get url, headers: oauth_token_headers(personal_access_token)
      end

      it 'request is authenticated by token in basic auth' do
        expect_authenticated_request

        get url, headers: basic_auth_headers(user, personal_access_token)
      end
    end

    context 'authenticated with OAuth token' do
      let(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user) }
      let(:oauth_token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "api") }

      it 'request is authenticated by token in query string' do
        expect_authenticated_request

        get url, params: { access_token: oauth_token.token }
      end

      it 'request is authenticated by token in the headers' do
        expect_authenticated_request

        get url, headers: oauth_token_headers(oauth_token)
      end
    end

    context 'authenticated with lfs token' do
      it 'request is authenticated by token in basic auth' do
        lfs_token = Gitlab::LfsToken.new(user)
        encoded_login = ["#{user.username}:#{lfs_token.token}"].pack('m0')

        expect_authenticated_request

        get url, headers: { 'AUTHORIZATION' => "Basic #{encoded_login}" }
      end
    end

    context 'authenticated with regular login' do
      it 'request is authenticated after login' do
        login_as(user)

        expect_authenticated_request

        get url
      end

      it 'request is authenticated by credentials in basic auth' do
        encoded_login = ["#{user.username}:#{user.password}"].pack('m0')

        expect_authenticated_request

        get url, headers: { 'AUTHORIZATION' => "Basic #{encoded_login}" }
      end
    end
  end
end
