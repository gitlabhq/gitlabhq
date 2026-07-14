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
  let(:aid) { 'shadow-spec-app-id' }
  let(:labkit_key) { "labkit:rl:rack_request:product_analytics_collector:aid:#{aid}" }

  def labkit_count
    Gitlab::Redis::RateLimiting.with { |redis| redis.get(labkit_key) }.to_i
  end

  # Sum labkit's counters for a rule across whatever discriminator value the
  # request produced, so the assertion need not know the request IP or user id.
  def labkit_count_for(rule)
    Gitlab::Redis::RateLimiting.with do |redis|
      redis.scan_each(match: "labkit:rl:rack_request:#{rule}:*").sum { |key| redis.get(key).to_i }
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

  describe 'an allowlisted user' do
    let_it_be(:token) { create(:personal_access_token) }

    before do
      allow(Gitlab::RackAttack).to receive(:user_allowlist).and_return(Set.new([token.user_id]))
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

    # An allowlisted user is authenticated, so they must escape the authenticated API
    # throttle (via the blank requester id) AND the unauthenticated one (they are not
    # anonymous) - as Rack::Attack does, where their throttled_identifer is nil and
    # unauthenticated? is false.
    it 'is exempt from both the authenticated and unauthenticated API throttles', :aggregate_failures do
      get '/api/v4/projects', params: { private_token: token.token }

      expect(labkit_count_for('authenticated_api')).to eq(0)
      expect(labkit_count_for('unauthenticated_api')).to eq(0)
    end
  end

  # The runner-jobs API path (/api/v4/jobs/*) is excluded from the authenticated API
  # throttle for authenticated requests (mirroring Rack::Attack's runner_jobs_request?),
  # but the exclusion is gated on requester presence, not path alone, so anonymous
  # requests to it are still throttled - otherwise enforce mode would open an
  # unauthenticated hole on the runner API.
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

    # An authenticated request on this path is claimed by the runner_jobs :skip rule,
    # which terminates without counting - so no counter moves at all, for a request
    # the sibling example shows would otherwise count. This also documents the
    # accepted divergence: a PAT (neither runner nor job token) to /api/v4/jobs/* is
    # throttled by Rack::Attack but skipped here, since no identity fact distinguishes
    # a PAT user from a job-token user on a jobs path.
    it 'skips an authenticated request out of authenticated_api without counting', :aggregate_failures do
      token = create(:personal_access_token)

      get '/api/v4/jobs/1/trace', params: { private_token: token.token }

      expect(labkit_count_for('authenticated_api')).to eq(0)
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
