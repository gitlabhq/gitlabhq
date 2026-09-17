# frozen_string_literal: true

require 'spec_helper'

# End-to-end proof that Gitlab::RackAttack.configure_throttles's
# labkit_fully_enforced safelist (lib/gitlab/rack_attack.rb) makes Rack::Attack
# a transparent pass-through, now that every Labkit cohort unconditionally
# enforces: Rack::Attack's own throttles are never consulted, and Labkit's
# headers are the only ones a response ever carries. See
# lib/gitlab/rack_attack/labkit_rate_limit/labkit-enforce-usecases.md for the
# request flow this closes (the Case C double-check).
RSpec.describe 'Rack::Attack safelisted once Labkit fully enforces',
  :clean_gitlab_redis_rate_limiting, feature_category: :rate_limiting do
  let(:ip) { '203.0.113.5' }

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
  end

  it 'is not blocked - Rack::Attack is safelisted and never independently enforces' do
    make_request

    expect(response).not_to have_gitlab_http_status(:too_many_requests)
  end

  it 'carries proactive RateLimit-* headers built from labkit counters', :aggregate_failures do
    make_request

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers['RateLimit-Name']).to eq('throttle_unauthenticated_api')
    expect(response.headers['RateLimit-Observed']).to eq('1')
    expect(response.headers['RateLimit-Remaining']).to eq('0')
  end
end
