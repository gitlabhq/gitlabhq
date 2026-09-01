# frozen_string_literal: true

require 'spec_helper'

# End-to-end coverage of Gitlab::Middleware::LabkitRackRateLimit through the full
# Rack stack (mounted above Rack::Attack). In shadow mode a real request reaches
# the inbound path, which builds labkit's identifier and increments labkit's
# counter in its own keyspace without changing the response. In enforce mode the
# same path renders the 429 directly. Each case confirms the per-cohort flag
# gates the behaviour at the middleware position.
#
# The product-analytics collector is used because it fires on path alone (no
# auth, no enable setting) and counts by the `aid` query parameter. The
# unauthenticated and authenticated API throttles below cover the dimensions it
# skips (an enable setting, an IP discriminator, and authenticated identity
# resolution), each with the cohort flag in both states.
RSpec.describe 'Labkit::RateLimit rack middleware', :clean_gitlab_redis_rate_limiting, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax
  include RackAttackSpecHelpers
  include WorkhorseHelpers

  let(:aid) { 'shadow-spec-app-id' }
  let(:labkit_key) { "labkit:rl:{rack_request:product_analytics_collector:aid:#{aid}}" }

  # Shared by every table below that needs an authenticated requester; tables
  # needing extra fixtures (a project, a group) define those locally.
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { create(:personal_access_token, user: user) }
  let(:private_token_params) { { private_token: token.token } }

  def labkit_count
    Gitlab::Redis::RateLimiting.with { |redis| redis.get(labkit_key) }.to_i
  end

  # Sum labkit's counters for a rule across whatever discriminator value the
  # request produced, so the assertion need not know the request IP or user id.
  def labkit_count_for(rule)
    Gitlab::Redis::RateLimiting.with do |redis|
      redis.scan_each(match: "labkit:rl:{rack_request:#{rule}:*").sum { |key| redis.get(key).to_i }
    end
  end

  context 'when the throttle cohort shadow flag is on' do
    before do
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_1: true)
    end

    it 'increments labkit\'s counter in parallel and does not block the request' do
      get "/-/collector/i?aid=#{aid}"

      expect(response).not_to have_gitlab_http_status(:too_many_requests)
      expect(labkit_count).to eq(1)
    end
  end

  context 'when the throttle cohort shadow flag is off' do
    before do
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_1: false)
    end

    it 'does not run the shadow, leaving labkit untouched' do
      get "/-/collector/i?aid=#{aid}"

      expect(labkit_count).to eq(0)
    end
  end

  describe 'an unauthenticated API throttle (enable setting + IP discriminator)' do
    before do
      stub_application_setting(
        throttle_unauthenticated_api_enabled: true,
        throttle_unauthenticated_api_requests_per_period: 1000,
        throttle_unauthenticated_api_period_in_seconds: 60
      )
    end

    context 'when the cohort shadow flag is on' do
      before do
        stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true)
      end

      it 'counts in labkit without blocking the request' do
        get '/api/v4/projects'

        expect(response).not_to have_gitlab_http_status(:too_many_requests)
        expect(labkit_count_for('unauthenticated_api')).to eq(1)
      end
    end

    context 'when the cohort shadow flag is off' do
      before do
        stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: false)
      end

      it 'leaves labkit untouched' do
        get '/api/v4/projects'

        expect(labkit_count_for('unauthenticated_api')).to eq(0)
      end
    end
  end

  describe 'an authenticated API throttle (identity resolution + requester discriminator)' do
    let_it_be(:token) { create(:personal_access_token) }

    before do
      stub_application_setting(
        throttle_authenticated_api_enabled: true,
        throttle_authenticated_api_requests_per_period: 1000,
        throttle_authenticated_api_period_in_seconds: 60
      )
    end

    context 'when the cohort shadow flag is on' do
      before do
        stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true)
      end

      it 'counts the authenticated requester in labkit without blocking the request' do
        get '/api/v4/projects', params: { private_token: token.token }

        expect(response).not_to have_gitlab_http_status(:too_many_requests)
        expect(labkit_count_for('authenticated_api')).to eq(1)
      end
    end

    context 'when the cohort shadow flag is off' do
      before do
        stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: false)
      end

      it 'leaves labkit untouched' do
        get '/api/v4/projects', params: { private_token: token.token }

        expect(labkit_count_for('authenticated_api')).to eq(0)
      end
    end
  end

  # Tables below use only plain values or ref()/lazy{} - never a proc - per the
  # testing guide's table-based tests section. perform_request dispatches generically
  # off each table's :method/:path/:params/:headers/:login_as_user columns.
  def perform_request
    login_as(user) if login_as_user
    public_send(method, path, params: params, headers: headers)
  end

  # Shadow+enforce a single cohort - what every table below needs to prove its own
  # throttles block. The "dry run" describe further down enables every cohort at
  # once instead, for a different reason (Rack::Attack's own boot-time throttling).
  def enable_cohort!(cohort)
    stub_feature_flags(
      "rate_limiter_use_labkit_rack_cohort_#{cohort}": true,
      "rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce": true
    )
  end

  # Shared by tables whose throttles each have their own <prefix>_enabled/
  # _requests_per_period/_period_in_seconds setting group; the protected-paths and
  # bypass/allowlist tables below override this locally with their own shape.
  def stub_throttle_settings(enabled:)
    stub_application_setting(
      "#{setting_prefix}_enabled": enabled,
      "#{setting_prefix}_requests_per_period": 1,
      "#{setting_prefix}_period_in_seconds": 60
    )
  end

  shared_examples 'a labkit-enforced throttle toggle' do
    it 'rejects requests over the rate limit with the full RateLimit-* header set', :aggregate_failures do
      stub_throttle_settings(enabled: true)

      perform_request
      expect(response).not_to have_gitlab_http_status(:too_many_requests)

      expect_rejection(throttle_name) { perform_request }
    end

    it 'does not block requests over the same limit when the throttle setting is disabled', :aggregate_failures do
      stub_throttle_settings(enabled: false)

      3.times do
        perform_request
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  shared_examples 'an exempt labkit throttle' do
    it 'is exempt from the throttle and writes no counter for it', :aggregate_failures do
      stub_throttle_settings

      3.times do
        perform_request
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end

      expect(labkit_count_for(throttle_name.delete_prefix('throttle_'))).to eq(0)
    end
  end

  # Table-based coverage for the four "general" throttles (see
  # Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry::GENERAL, cohort 2).
  describe 'general web and API throttles' do
    let(:headers) { {} }

    before do
      enable_cohort!(2)
    end

    # setting_prefix follows the uniform <prefix>_enabled/_requests_per_period/
    # _period_in_seconds naming every one of these four throttles uses.
    where(:throttle_name, :setting_prefix, :method, :path, :params, :login_as_user) do
      'throttle_unauthenticated_web' | 'throttle_unauthenticated'     | :get | '/users/sign_in'      | {} | false
      'throttle_authenticated_web'   | 'throttle_authenticated_web'   | :get | '/dashboard/snippets' | {} | true
      'throttle_unauthenticated_api' | 'throttle_unauthenticated_api' | :get | '/api/v4/projects'    | {} | false
      'throttle_authenticated_api' | 'throttle_authenticated_api' | :get | '/api/v4/projects' |
        ref(:private_token_params) | false
    end

    with_them { include_examples 'a labkit-enforced throttle toggle' }
  end

  # Table-based coverage for the specialized-path throttles (packages, files,
  # deprecated), cohort 1.
  describe 'specialized API throttles' do
    let_it_be(:project) { create(:project, :public, :custom_repo, files: { 'README' => 'foo' }) }
    let_it_be(:group) { create(:group, :public) }
    let(:files_token_params) { { ref: 'master', private_token: token.token } }
    let(:headers) { {} }

    before do
      enable_cohort!(1)
    end

    where(:throttle_name, :setting_prefix, :method, :path, :params) do
      'throttle_unauthenticated_packages_api' | 'throttle_unauthenticated_packages_api' | :get |
        lazy { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" } | {}
      'throttle_authenticated_packages_api' | 'throttle_authenticated_packages_api' | :get |
        lazy { "/api/v4/projects/#{project.id}/packages/conan/v1/ping" } | ref(:private_token_params)
      'throttle_unauthenticated_files_api' | 'throttle_unauthenticated_files_api' | :get |
        lazy { "/api/v4/projects/#{project.id}/repository/files/README" } | { ref: 'master' }
      'throttle_authenticated_files_api' | 'throttle_authenticated_files_api' | :get |
        lazy { "/api/v4/projects/#{project.id}/repository/files/README" } | ref(:files_token_params)
      'throttle_unauthenticated_deprecated_api' | 'throttle_unauthenticated_deprecated_api' | :get |
        lazy { "/api/v4/groups/#{group.id}" } | {}
      'throttle_authenticated_deprecated_api' | 'throttle_authenticated_deprecated_api' | :get |
        lazy { "/api/v4/groups/#{group.id}" } | ref(:private_token_params)
    end

    with_them do
      let(:login_as_user) { false }

      include_examples 'a labkit-enforced throttle toggle'
    end
  end

  # Table-based coverage for the git throttles (git_http unauth/auth, git_lfs auth),
  # cohort 3.
  describe 'git throttles' do
    let_it_be(:project) { create(:project, :small_repo, :public) }
    let(:git_auth_headers) { workhorse_internal_api_request_header.merge(basic_auth_headers(user, token)) }

    before do
      enable_cohort!(3)
    end

    where(:throttle_name, :setting_prefix, :method, :path, :headers) do
      'throttle_unauthenticated_git_http' | 'throttle_unauthenticated_git_http' | :get |
        '/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack' | {}
      'throttle_authenticated_git_http' | 'throttle_authenticated_git_http' | :get |
        lazy { "/#{project.full_path}.git/info/refs?service=git-upload-pack" } | ref(:git_auth_headers)
      'throttle_authenticated_git_lfs' | 'throttle_authenticated_git_lfs' | :get |
        lazy { "/#{project.full_path}.git/info/lfs/locks" } | ref(:git_auth_headers)
    end

    with_them do
      let(:params) { {} }
      let(:login_as_user) { false }

      include_examples 'a labkit-enforced throttle toggle'
    end
  end

  # Unlike the tables above, all six throttles here share ONE setting group
  # (throttle_protected_paths_*); what varies is which admin path list applies
  # (protected_paths vs protected_paths_for_get_request) - path doubles as both.
  describe 'protected-paths throttles' do
    let(:headers) { {} }

    before do
      enable_cohort!(3)
    end

    # Deliberately overrides the top-level stub_throttle_settings by name, not a
    # naming collision: the shared example calls it generically, so this table's
    # different setting shape must be reachable under the same method name.
    def stub_throttle_settings(enabled:)
      stub_application_setting(
        throttle_protected_paths_enabled: enabled,
        throttle_protected_paths_requests_per_period: 1,
        throttle_protected_paths_period_in_seconds: 60,
        setting_key => [path]
      )
    end

    where(:throttle_name, :setting_key, :method, :path, :params, :login_as_user) do
      'throttle_unauthenticated_protected_paths' | :protected_paths | :post | '/users/sign_in' |
        { user: { login: 'a-user', password: 'a-password' } } | false
      'throttle_authenticated_protected_paths_api' | :protected_paths | :post | '/api/v4/user/emails' |
        ref(:private_token_params) | false
      'throttle_authenticated_protected_paths_web' | :protected_paths | :post | '/users/confirmation' |
        {} | true
      'throttle_unauthenticated_get_protected_paths' | :protected_paths_for_get_request | :get |
        '/users/sign_in' | {} | false
      'throttle_authenticated_get_protected_paths_api' | :protected_paths_for_get_request | :get |
        '/api/v4/user/emails' | ref(:private_token_params) | false
      'throttle_authenticated_get_protected_paths_web' | :protected_paths_for_get_request | :get |
        '/users/confirmation' | {} | true
    end

    with_them { include_examples 'a labkit-enforced throttle toggle' }
  end

  # The bypass rule is one :skip on every limiter, ahead of any throttle's own
  # counting rule (Limiters::BYPASS_RULE_NAME) - two representative throttles (one
  # unauthenticated, one authenticated) prove it generalizes across auth state.
  describe 'bypass header (GITLAB_THROTTLE_BYPASS_HEADER)' do
    let(:headers) { { 'Gitlab-Bypass' => '1' } }
    let(:login_as_user) { false }

    before do
      stub_env('GITLAB_THROTTLE_BYPASS_HEADER', 'GITLAB_BYPASS')
      enable_cohort!(2)
    end

    # Delegates to the top-level stub_throttle_settings(enabled:) instead of
    # rebuilding the same hash, since bypass always stubs it enabled.
    def stub_throttle_settings
      super(enabled: true)
    end

    where(:throttle_name, :setting_prefix, :method, :path, :params) do
      'throttle_unauthenticated_api' | 'throttle_unauthenticated_api' | :get | '/api/v4/projects' | {}
      'throttle_authenticated_api' | 'throttle_authenticated_api' | :get | '/api/v4/projects' |
        ref(:private_token_params)
    end

    with_them { include_examples 'an exempt labkit throttle' }
  end

  # The allowlist rule is one :skip on every limiter (Limiters::ALLOWLIST_RULE_NAME).
  # "an allowlisted user" below additionally proves mutual exemption from both API
  # throttles in a single request.
  describe 'user allowlist (GITLAB_THROTTLE_USER_ALLOWLIST)' do
    let(:headers) { {} }

    before do
      allow(Gitlab::RackAttack).to receive(:user_allowlist).and_return(Set.new([user.id]))
      # The allowlist is baked into the memoized rule set; rebuild it after stubbing.
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
      enable_cohort!(2)
    end

    after do
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
    end

    # Delegates to the top-level stub_throttle_settings(enabled:) instead of
    # rebuilding the same hash, since allowlist always stubs it enabled.
    def stub_throttle_settings
      super(enabled: true)
    end

    where(:throttle_name, :setting_prefix, :method, :path, :params, :login_as_user) do
      'throttle_authenticated_api' | 'throttle_authenticated_api' | :get | '/api/v4/projects' |
        ref(:private_token_params) | false
      'throttle_authenticated_web' | 'throttle_authenticated_web' | :get | '/dashboard/snippets' | {} | true
    end

    with_them { include_examples 'an exempt labkit throttle' }
  end

  # Naming a throttle swaps its rule to :log (see Limiters#build_rules). Every
  # cohort must be fully enforced (ThrottleRegistry.fully_enforced?): Rack::Attack's
  # own registration is fixed at boot, before this stub_env runs, so it still blocks.
  describe 'dry run (GITLAB_THROTTLE_DRY_RUN)' do
    before do
      labkit_flags = Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.cohorts.flat_map do |cohort|
        [
          :"rate_limiter_use_labkit_rack_cohort_#{cohort}",
          :"rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce"
        ]
      end
      stub_feature_flags(labkit_flags.index_with(true))
    end

    after do
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
    end

    it 'never blocks a dry-run throttle even over its limit', :aggregate_failures do
      stub_env('GITLAB_THROTTLE_DRY_RUN', 'throttle_unauthenticated_api')
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
      stub_application_setting(
        throttle_unauthenticated_api_enabled: true,
        throttle_unauthenticated_api_requests_per_period: 1,
        throttle_unauthenticated_api_period_in_seconds: 60
      )

      2.times do
        get '/api/v4/projects'
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end

    # throttle_unauthenticated_web predates the API/web split; naming the legacy
    # alias must still resolve to the modern throttle name (see
    # Gitlab::RackAttack.track?).
    it 'honors the legacy throttle_unauthenticated alias for the web throttle', :aggregate_failures do
      stub_env('GITLAB_THROTTLE_DRY_RUN', 'throttle_unauthenticated')
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
      stub_application_setting(
        throttle_unauthenticated_enabled: true,
        throttle_unauthenticated_requests_per_period: 1,
        throttle_unauthenticated_period_in_seconds: 60
      )

      2.times do
        get '/users/sign_in'
        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  # Real requests through the full stack for the ordering-sensitive throttles: a
  # packages request must be claimed by the packages rule (specialized before general
  # API), and a git request by a git rule (git before web), not the rule that would
  # claim it if the ordering were wrong.
  describe 'a specialized API throttle is claimed before the general API rule' do
    before do
      stub_application_setting(throttle_unauthenticated_packages_api_enabled: true)
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_1: true, rate_limiter_use_labkit_rack_cohort_2: true)
    end

    it 'counts a packages request under the packages rule, not unauthenticated_api', :aggregate_failures do
      get '/api/v4/projects/1/packages/npm/-/package/foo/dist-tags'

      expect(labkit_count_for('unauthenticated_packages_api')).to eq(1)
      expect(labkit_count_for('unauthenticated_api')).to eq(0)
    end
  end

  describe 'a git throttle is claimed before the web rule' do
    before do
      stub_application_setting(
        throttle_unauthenticated_git_http_enabled: true,
        throttle_unauthenticated_enabled: true
      )
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true, rate_limiter_use_labkit_rack_cohort_3: true)
    end

    it 'counts a git request under the git rule, not unauthenticated_web', :aggregate_failures do
      get '/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack'

      expect(labkit_count_for('unauthenticated_git_http')).to eq(1)
      expect(labkit_count_for('unauthenticated_web')).to eq(0)
    end
  end

  # Rack::Attack counts a collector request under both the collector and web
  # throttles (a collector path is also a web path); the collector rule claims it
  # here. Pins the known, accepted divergence rather than hiding it.
  describe 'a collector request with the web throttle enabled' do
    before do
      stub_application_setting(throttle_unauthenticated_enabled: true)
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_1: true, rate_limiter_use_labkit_rack_cohort_2: true)
    end

    it 'counts under the collector throttle only, under-counting web as Rack::Attack does not', :aggregate_failures do
      get "/-/collector/i?aid=#{aid}"

      expect(labkit_count).to eq(1)
      expect(labkit_count_for('unauthenticated_web')).to eq(0)
    end
  end

  describe 'an allowlisted user' do
    let_it_be(:token) { create(:personal_access_token) }

    before do
      allow(Gitlab::RackAttack).to receive(:user_allowlist).and_return(Set.new([token.user_id]))
      # The allowlist is baked into the memoized rule set; rebuild it after stubbing.
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
      stub_application_setting(
        throttle_authenticated_api_enabled: true,
        throttle_authenticated_api_requests_per_period: 1000,
        throttle_authenticated_api_period_in_seconds: 60,
        throttle_unauthenticated_api_enabled: true,
        throttle_unauthenticated_api_requests_per_period: 1000,
        throttle_unauthenticated_api_period_in_seconds: 60
      )
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true)
    end

    after do
      Gitlab::RackAttack::LabkitRateLimit::Limiters.reset!
    end

    # An allowlisted user is authenticated, so they must escape the authenticated API
    # throttle (claimed by the user_allowlist skip rule, which does not count) AND the
    # unauthenticated one (they are not anonymous) - as Rack::Attack does, where their
    # throttled_identifer is nil and unauthenticated? is false.
    it 'is exempt from both the authenticated and unauthenticated API throttles', :aggregate_failures do
      get '/api/v4/projects', params: { private_token: token.token }

      expect(labkit_count_for('authenticated_api')).to eq(0)
      expect(labkit_count_for('unauthenticated_api')).to eq(0)
    end
  end

  # The runner-jobs API path (/api/v4/jobs/*) excludes runner- and job-token-
  # authenticated requests from the authenticated API throttle (mirroring
  # Rack::Attack's runner_jobs_request?). The exclusion turns on the auth method, not
  # the path or bare requester presence: an anonymous request still counts under the
  # unauthenticated API throttle, and a PAT- or OAuth-authenticated request still
  # counts under the authenticated one, because only a runner or job token marks the
  # runner API traffic the throttle is meant to exempt.
  describe 'the runner-jobs API path' do
    before do
      stub_application_setting(
        throttle_unauthenticated_api_enabled: true,
        throttle_unauthenticated_api_requests_per_period: 1000,
        throttle_unauthenticated_api_period_in_seconds: 60,
        throttle_authenticated_api_enabled: true,
        throttle_authenticated_api_requests_per_period: 1000,
        throttle_authenticated_api_period_in_seconds: 60
      )
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true)
    end

    it 'still counts an anonymous request under unauthenticated_api', :aggregate_failures do
      get '/api/v4/jobs/1/trace'

      expect(labkit_count_for('unauthenticated_api')).to eq(1)
      expect(labkit_count_for('runner_jobs')).to eq(0)
    end

    # A PAT is neither a runner nor a job token, so a PAT request on this path is not
    # a runner_jobs_request: the runner_jobs skip rule does not claim it and it falls
    # through to the authenticated API throttle, counted exactly as Rack::Attack
    # counts it (a PAT-driven bot polling job status is real API usage). This is the
    # parity fix - skipping on the path alone left this request invisible to labkit
    # while Rack::Attack throttled it. runner_jobs writes no counter of its own.
    it 'counts a PAT-authenticated request under authenticated_api, matching Rack::Attack', :aggregate_failures do
      token = create(:personal_access_token)

      get '/api/v4/jobs/1/trace', params: { private_token: token.token }

      expect(labkit_count_for('authenticated_api')).to eq(1)
      expect(labkit_count_for('unauthenticated_api')).to eq(0)
      expect(labkit_count_for('runner_jobs')).to eq(0)
    end
  end

  context 'when the throttle cohort enforce flag is on' do
    before do
      stub_feature_flags(
        rate_limiter_use_labkit_rack_cohort_1: true,
        rate_limiter_use_labkit_rack_cohort_1_enforce: true
      )
    end

    # Pre-seed only labkit's counter to the product-analytics limit (100/60), so
    # the request's own increment tips labkit over while Rack::Attack's separate
    # counter is still at zero. A 429 therefore proves labkit enforced it: the
    # middleware short-circuits above Rack::Attack, which would have allowed it.
    it 'blocks the request with a 429 from labkit, not Rack::Attack' do
      Gitlab::Redis::RateLimiting.with { |redis| redis.set(labkit_key, 100) }

      get "/-/collector/i?aid=#{aid}"

      expect(response).to have_gitlab_http_status(:too_many_requests)
      expect(response.headers['RateLimit-Name']).to eq('throttle_product_analytics_collector')
    end
  end

  context 'when the bypass header is set' do
    before do
      stub_env('GITLAB_THROTTLE_BYPASS_HEADER', 'GITLAB_BYPASS')
      stub_feature_flags(
        rate_limiter_use_labkit_rack_cohort_1: true,
        rate_limiter_use_labkit_rack_cohort_1_enforce: true
      )
    end

    # Even with labkit's counter pre-seeded over the limit and enforce on, a bypassed
    # request is allowed: labkit's bypass :skip rule matches first and terminates the
    # limiter before the throttle rule, mirroring the Rack::Attack safelist
    # short-circuit. The allowed response is the proof the bypass claimed the request;
    # :skip writes no counter of its own.
    it 'skips the throttle, is not blocked, and writes no bypass counter', :aggregate_failures do
      Gitlab::Redis::RateLimiting.with { |redis| redis.set(labkit_key, 100) }

      get "/-/collector/i?aid=#{aid}", headers: { 'Gitlab-Bypass' => '1' }

      expect(response).not_to have_gitlab_http_status(:too_many_requests)
      expect(labkit_count).to eq(100) # the product-analytics counter is untouched
      expect(labkit_count_for('bypass_header')).to eq(0)
    end
  end
end
