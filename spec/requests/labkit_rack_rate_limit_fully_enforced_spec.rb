# frozen_string_literal: true

require 'spec_helper'

# End-to-end proof that Gitlab::RackAttack.configure_throttles's
# labkit_fully_enforced safelist (lib/gitlab/rack_attack.rb) makes Rack::Attack
# a transparent pass-through once every Labkit cohort both shadows and
# enforces: its own throttle counters are never consulted, even when they are
# already over limit. See
# lib/gitlab/rack_attack/labkit_rate_limit/labkit-enforce-usecases.md for the
# request flow this closes (the Case C double-check).
RSpec.describe 'Rack::Attack safelisted once Labkit fully enforces',
  :clean_gitlab_redis_rate_limiting, feature_category: :rate_limiting do
  let(:ip) { '203.0.113.5' }
  let(:cohorts) { Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.cohorts }

  def stub_shadow_and_enforce(cohort, shadow:, enforce:)
    stub_feature_flags(
      "rate_limiter_use_labkit_rack_cohort_#{cohort}": shadow,
      "rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce": enforce
    )
  end

  def make_request
    get '/api/v4/projects', headers: { 'REMOTE_ADDR' => ip }
  end

  around do |example|
    freeze_time { example.run }
  end

  before do
    stub_application_setting(
      throttle_unauthenticated_api_enabled: true,
      throttle_unauthenticated_api_requests_per_period: 1
    )

    # Drive Rack::Attack's own counter over its limit via real traffic, while
    # every cohort flag is still at its suite-wide default (off - see
    # spec/support/rate_limiter_labkit_rack_shadow.rb). With shadow off,
    # LabkitRackRateLimit#run never executes, so these warm-up requests only
    # touch Rack::Attack's counter, leaving Labkit's completely untouched.
    2.times { make_request }
  end

  context 'when not every cohort both shadows and enforces (default state)' do
    it 'is blocked - Rack::Attack independently sees its own over-limit counter' do
      make_request

      expect(response).to have_gitlab_http_status(:too_many_requests)
    end
  end

  context 'when every cohort enforces but none shadow (misconfiguration)' do
    before do
      cohorts.each { |cohort| stub_shadow_and_enforce(cohort, shadow: false, enforce: true) }
    end

    it 'is still blocked - fully_enforced? requires shadow too, so Rack::Attack keeps throttling' do
      make_request

      expect(response).to have_gitlab_http_status(:too_many_requests)
    end
  end

  context 'when every cohort both shadows and enforces' do
    before do
      cohorts.each { |cohort| stub_shadow_and_enforce(cohort, shadow: true, enforce: true) }
    end

    it 'is not blocked - Rack::Attack is safelisted and never consults its own (already over-limit) counter' do
      make_request

      expect(response).not_to have_gitlab_http_status(:too_many_requests)
    end

    it 'carries proactive RateLimit-* headers built from labkit counters', :aggregate_failures do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
      # Labkit's counter saw only this one request. Rack::Attack's counter sits at 2
      # from the warm-up, so an Observed of 1 proves the headers no longer come from
      # the safelisted legacy stack (production-engineering#29539).
      expect(response.headers['RateLimit-Observed']).to eq('1')
      expect(response.headers['RateLimit-Remaining']).to eq('0')
    end
  end
end
