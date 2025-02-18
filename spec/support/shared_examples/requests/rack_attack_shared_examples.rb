# frozen_string_literal: true

#
# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_api", "throttle_authenticated_web", "throttle_protected_paths", "throttle_authenticated_packages_api", "throttle_authenticated_git_lfs", "throttle_authenticated_files_api", "throttle_authenticated_deprecated_api"
# * request_method
# * request_args
# * other_user_request_args
# * requests_per_period
# * period_in_seconds
# * period
RSpec.shared_examples 'rate-limited user based token-authenticated requests' do
  context 'when the throttle is enabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
      stub_application_setting(settings_to_set)
    end

    it 'does not reject requests if the user is in the allowlist' do
      stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', user.id.to_s)
      Gitlab::RackAttack.configure_user_allowlist

      expect(Gitlab::Instrumentation::Throttle).to receive(:safelist=).with('throttle_user_allowlist').at_least(:once)

      (requests_per_period + 1).times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', nil)
      Gitlab::RackAttack.configure_user_allowlist
    end
  end

  include_examples 'rate-limited token requests' do
    let(:log_data) do
      {
        user_id: user.id,
        'meta.user' => user.username
      }
    end
  end
end

RSpec.shared_examples 'rate-limited deploy-token-authenticated requests' do
  include_examples 'rate-limited token requests' do
    let(:log_data) do
      {
        deploy_token_id: deploy_token.id
      }
    end
  end
end

RSpec.shared_examples 'rate-limited token requests' do
  let(:throttle_types) do
    {
      "throttle_protected_paths" => "throttle_authenticated_protected_paths_api",
      "throttle_authenticated_api" => "throttle_authenticated_api",
      "throttle_authenticated_web" => "throttle_authenticated_web",
      "throttle_authenticated_packages_api" => "throttle_authenticated_packages_api",
      "throttle_authenticated_git_lfs" => "throttle_authenticated_git_lfs",
      "throttle_authenticated_files_api" => "throttle_authenticated_files_api",
      "throttle_authenticated_deprecated_api" => "throttle_authenticated_deprecated_api"
    }
  end

  before do
    # Set low limits
    settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
    settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
    travel_back
  end

  after do
    stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', nil)
    Gitlab::RackAttack.configure_user_allowlist
  end

  context 'when the throttle is enabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
      stub_application_setting(settings_to_set)
    end

    it 'rejects requests over the rate limit' do
      expect(Gitlab::Instrumentation::Throttle).not_to receive(:safelist=)

      # At first, allow requests under the rate limit.
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      # the last straw
      expect_rejection { make_request(request_args) }
    end

    it 'allows requests after throttling and then waiting for the next period' do
      # ensure we don't tick over to the next second while hitting this period's rate limit
      # before calculating the time for the next period
      next_period = period.from_now

      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      expect_rejection { make_request(request_args) }

      travel_to(next_period) do
        requests_per_period.times do
          make_request(request_args)
          expect(response).not_to have_gitlab_http_status(:too_many_requests)
        end

        expect_rejection { make_request(request_args) }
      end
    end

    it 'counts requests from different requesters separately, even from the same IP' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      # would be over the limit if this wasn't a different user
      make_request(other_user_request_args)
      expect(response).not_to have_gitlab_http_status(:too_many_requests)
    end

    it 'counts all requests from the same requesters, even via different IPs' do
      requests_per_period.times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      expect_any_instance_of(Rack::Attack::Request).to receive(:ip).at_least(:once).and_return('1.2.3.4')

      expect_rejection { make_request(request_args) }
    end

    it 'logs RackAttack info into structured logs' do
      control_count = 0

      requests_per_period.times do |i|
        if i == 0
          control_count = ActiveRecord::QueryRecorder.new { make_request(request_args) }.count
        else
          make_request(request_args)
        end

        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      matched = throttle_types[throttle_setting_prefix]

      if request_method == 'GET' && throttle_setting_prefix == 'throttle_protected_paths'
        matched = 'throttle_authenticated_get_protected_paths_api'
      end

      arguments = a_hash_including({
        message: 'Rack_Attack',
        status: 429,
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: request_method,
        path: a_string_including(request_args.first.split('?').first),
        matched: matched
      }.merge(log_data))

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once

      expect_rejection do
        expect { make_request(request_args) }.not_to exceed_query_limit(control_count)
      end
    end

    it_behaves_like 'tracking when dry-run mode is set' do
      let(:throttle_name) do
        name = throttle_types[throttle_setting_prefix]
        if request_method == 'GET' && throttle_setting_prefix == 'throttle_protected_paths'
          name = 'throttle_authenticated_get_protected_paths_api'
        end

        name
      end

      def do_request
        make_request(request_args)
      end
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        make_request(request_args)
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  def make_request(args)
    path, options = args
    if request_method == 'POST'
      post(path, **options)
    else
      get(path, **options)
    end
  end
end

# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated_web", "throttle_protected_paths", "throttle_authenticated_git_lfs"
# * user
# * url_that_requires_authentication
# * request_method
# * requests_per_period
# * period_in_seconds
# * period
RSpec.shared_examples 'rate-limited web authenticated requests' do
  let(:throttle_types) do
    {
      "throttle_protected_paths" => "throttle_authenticated_protected_paths_web",
      "throttle_authenticated_web" => "throttle_authenticated_web",
      "throttle_authenticated_git_lfs" => "throttle_authenticated_git_lfs"
    }
  end

  before do
    login_as(user)

    # Set low limits
    settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
    settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
    travel_back
  end

  after do
    stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', nil)
    Gitlab::RackAttack.configure_user_allowlist
  end

  context 'when the throttle is enabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
      stub_application_setting(settings_to_set)
    end

    it 'rejects requests over the rate limit' do
      expect(Gitlab::Instrumentation::Throttle).not_to receive(:safelist=)

      # At first, allow requests under the rate limit.
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      # the last straw
      expect_rejection { request_authenticated_web_url }
    end

    it 'does not reject requests if the user is in the allowlist' do
      stub_env('GITLAB_THROTTLE_USER_ALLOWLIST', user.id.to_s)
      Gitlab::RackAttack.configure_user_allowlist

      expect(Gitlab::Instrumentation::Throttle).to receive(:safelist=).with('throttle_user_allowlist').at_least(:once)

      (requests_per_period + 1).times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end

    it 'allows requests after throttling and then waiting for the next period' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      expect_rejection { request_authenticated_web_url }

      travel_to(period.from_now) do
        requests_per_period.times do
          request_authenticated_web_url
          expect(response).not_to have_gitlab_http_status(:too_many_requests)
        end

        expect_rejection { request_authenticated_web_url }
      end
    end

    it 'counts requests from different users separately, even from the same IP' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      # would be over the limit if this wasn't a different user
      login_as(create(:user))

      request_authenticated_web_url
      expect(response).not_to have_gitlab_http_status(:too_many_requests)
    end

    it 'counts all requests from the same user, even via different IPs' do
      requests_per_period.times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      expect_any_instance_of(Rack::Attack::Request).to receive(:ip).at_least(:once).and_return('1.2.3.4')

      expect_rejection { request_authenticated_web_url }
    end

    it 'logs RackAttack info into structured logs' do
      control_count = 0

      requests_per_period.times do |i|
        if i == 0
          control_count = ActiveRecord::QueryRecorder.new { request_authenticated_web_url }.count
        else
          request_authenticated_web_url
        end

        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      matched = throttle_types[throttle_setting_prefix]

      if request_method == 'GET' && throttle_setting_prefix == 'throttle_protected_paths'
        matched = 'throttle_authenticated_get_protected_paths_web'
      end

      arguments = a_hash_including(
        message: 'Rack_Attack',
        status: 429,
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: request_method,
        path: url_that_requires_authentication,
        user_id: user.id,
        'meta.user' => user.username,
        matched: matched
      )

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments).once
      expect { request_authenticated_web_url }.not_to exceed_query_limit(control_count)
    end

    it_behaves_like 'tracking when dry-run mode is set' do
      let(:throttle_name) do
        name = throttle_types[throttle_setting_prefix]
        if request_method == 'GET' && throttle_setting_prefix == 'throttle_protected_paths'
          name = 'throttle_authenticated_get_protected_paths_web'
        end

        name
      end

      def do_request
        request_authenticated_web_url
      end
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        request_authenticated_web_url
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  def request_authenticated_web_url
    if request_method == 'POST'
      post url_that_requires_authentication
    else
      get url_that_requires_authentication
    end
  end
end

# Requires:
# - #do_request - This needs to be a method so the result isn't memoized
# - throttle_name
RSpec.shared_examples 'tracking when dry-run mode is set' do
  let(:dry_run_config) { '*' }

  # we can't use `around` here, because stub_env isn't supported outside of the
  # example itself
  before do
    stub_env('GITLAB_THROTTLE_DRY_RUN', dry_run_config)
    reset_rack_attack
  end

  after do
    stub_env('GITLAB_THROTTLE_DRY_RUN', '')
    reset_rack_attack
  end

  def reset_rack_attack
    Gitlab::Redis::RateLimiting.with(&:flushdb)
    Rack::Attack.clear_configuration
    Gitlab::RackAttack.configure(Rack::Attack)
  end

  it 'does not throttle the requests when `*` is configured' do
    (1 + requests_per_period).times do
      do_request
      expect(response).not_to have_gitlab_http_status(:too_many_requests)
    end
  end

  it 'logs RackAttack info into structured logs' do
    expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
      expect(arguments).to include(
        message: 'Rack_Attack',
        env: :track,
        remote_ip: '127.0.0.1',
        matched: throttle_name
      )

      expect(arguments).not_to have_key(:status)
    end

    (1 + requests_per_period).times do
      do_request
    end
  end

  context 'when configured with the the throttled name in a list' do
    let(:dry_run_config) do
      "throttle_list, #{throttle_name}, other_throttle"
    end

    it 'does not throttle' do
      (1 + requests_per_period).times do
        do_request
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end

# Requires let variables:
# * throttle_name: "throttle_unauthenticated_api", "throttle_unauthenticated_web"
# * throttle_setting_prefix: "throttle_unauthenticated_api", "throttle_unauthenticated"
# * url_that_does_not_require_authentication
# * url_that_is_not_matched
# * requests_per_period
# * period_in_seconds
# * period
# * headers
RSpec.shared_examples 'rate-limited unauthenticated requests' do
  let(:headers) { {} }

  before do
    # Set low limits
    settings_to_set[:"#{throttle_setting_prefix}_requests_per_period"] = requests_per_period
    settings_to_set[:"#{throttle_setting_prefix}_period_in_seconds"] = period_in_seconds
    travel_back
  end

  def do_request
    get url_that_does_not_require_authentication, headers: headers
  end

  context 'when the throttle is enabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = true
      stub_application_setting(settings_to_set)
    end

    it 'rejects requests over the rate limit' do
      # At first, allow requests under the rate limit.
      requests_per_period.times do
        do_request
        expect(response).to have_gitlab_http_status(:ok)
      end

      # the last straw
      expect_rejection { do_request }
    end

    context 'with custom response text' do
      before do
        stub_application_setting(rate_limiting_response_text: 'Custom response')
      end

      it 'rejects requests over the rate limit' do
        # At first, allow requests under the rate limit.
        requests_per_period.times do
          do_request
          expect(response).to have_gitlab_http_status(:ok)
        end

        # the last straw
        expect_rejection { do_request }
        expect(response.body).to eq("Custom response\n")
      end
    end

    it 'allows requests after throttling and then waiting for the next period' do
      requests_per_period.times do
        do_request
        expect(response).to have_gitlab_http_status(:ok)
      end

      expect_rejection { do_request }

      travel_to(period.from_now) do
        requests_per_period.times do
          do_request
          expect(response).to have_gitlab_http_status(:ok)
        end

        expect_rejection { do_request }
      end
    end

    it 'counts requests from different IPs separately' do
      requests_per_period.times do
        do_request
        expect(response).to have_gitlab_http_status(:ok)
      end

      expect_next_instance_of(Rack::Attack::Request) do |instance|
        expect(instance).to receive(:ip).at_least(:once).and_return('1.2.3.4')
      end

      # would be over limit for the same IP
      do_request
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the request is not matched by the throttle' do
      it 'does not throttle the requests' do
        (1 + requests_per_period).times do
          get url_that_is_not_matched
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the request is to the api internal endpoints' do
      it 'allows requests over the rate limit' do
        (1 + requests_per_period).times do
          get '/api/v4/internal/check', headers: GitlabShellHelpers.gitlab_shell_internal_api_request_header
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
        do_request
        expect(response).to have_gitlab_http_status(:ok)
      end

      arguments = a_hash_including({
        message: 'Rack_Attack',
        status: 429,
        env: :throttle,
        remote_ip: '127.0.0.1',
        request_method: 'GET',
        path: url_that_does_not_require_authentication,
        matched: throttle_name
      })

      expect(Gitlab::AuthLogger).to receive(:error).with(arguments)

      do_request
    end

    it_behaves_like 'tracking when dry-run mode is set' do
      def do_request
        get url_that_does_not_require_authentication, headers: headers
      end
    end
  end

  context 'when the throttle is disabled' do
    before do
      settings_to_set[:"#{throttle_setting_prefix}_enabled"] = false
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        do_request
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end

# Requires let variables:
# * throttle_setting_prefix: "throttle_authenticated", "throttle_unauthenticated"
RSpec.shared_examples 'rate-limited frontend API requests' do
  let(:requests_per_period) { 1 }
  let(:csrf_token) { SecureRandom.base64(ActionController::RequestForgeryProtection::AUTHENTICITY_TOKEN_LENGTH) }
  let(:csrf_session) { { _csrf_token: csrf_token } }
  let(:personal_access_token) { nil }

  let(:api_path) { '/projects' }

  # These don't actually exist, so a 404 is the expected response.
  let(:files_api_path) { '/projects/1/repository/files/ref/path' }
  let(:packages_api_path) { '/projects/1/packages/foo' }
  let(:deprecated_api_path) { '/groups/1?with_projects=true' }

  def get_api(path: api_path, csrf: false)
    headers = csrf ? { 'X-CSRF-Token' => csrf_token } : nil
    get api(path, personal_access_token: personal_access_token), headers: headers
  end

  def expect_not_found(&block)
    yield

    expect(response).to have_gitlab_http_status(:not_found)
  end

  before do
    stub_application_setting(
      "#{throttle_setting_prefix}_enabled" => true,
      "#{throttle_setting_prefix}_requests_per_period" => requests_per_period,
      "#{throttle_setting_prefix}_api_enabled" => true,
      "#{throttle_setting_prefix}_api_requests_per_period" => requests_per_period,
      "#{throttle_setting_prefix}_web_enabled" => true,
      "#{throttle_setting_prefix}_web_requests_per_period" => requests_per_period,
      "#{throttle_setting_prefix}_files_api_enabled" => true,
      "#{throttle_setting_prefix}_packages_api_enabled" => true,
      "#{throttle_setting_prefix}_deprecated_api_enabled" => true
    )

    stub_session(session_data: csrf_session)
  end

  context 'with a CSRF token' do
    it 'uses the rate limit for web requests' do
      requests_per_period.times { get_api csrf: true }

      expect_rejection("#{throttle_setting_prefix}_web") { get_api csrf: true }
      expect_rejection("#{throttle_setting_prefix}_web") { get_api csrf: true, path: files_api_path }
      expect_rejection("#{throttle_setting_prefix}_web") { get_api csrf: true, path: packages_api_path }
      expect_rejection("#{throttle_setting_prefix}_web") { get_api csrf: true, path: deprecated_api_path }

      # API rate limit is not triggered yet
      expect_ok { get_api }
      expect_not_found { get_api path: files_api_path }
      expect_not_found { get_api path: packages_api_path }
      expect_not_found { get_api path: deprecated_api_path }
    end

    context 'without a CSRF session' do
      let(:csrf_session) { nil }

      it 'always uses the rate limit for API requests' do
        requests_per_period.times { get_api csrf: true }

        expect_rejection("#{throttle_setting_prefix}_api") { get_api csrf: true }
        expect_rejection("#{throttle_setting_prefix}_api") { get_api }
      end
    end
  end

  context 'without a CSRF token' do
    it 'uses the rate limit for API requests' do
      requests_per_period.times { get_api }

      expect_rejection("#{throttle_setting_prefix}_api") { get_api }

      # Web and custom API rate limits are not triggered yet
      expect_ok { get_api csrf: true }
      expect_not_found { get_api path: files_api_path }
      expect_not_found { get_api path: packages_api_path }
      expect_not_found { get_api path: deprecated_api_path }
    end
  end
end
