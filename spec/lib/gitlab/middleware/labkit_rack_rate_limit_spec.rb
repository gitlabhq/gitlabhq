# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::LabkitRackRateLimit, feature_category: :rate_limiting do
  let(:registry) { Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry }
  let(:limiters) { Gitlab::RackAttack::LabkitRateLimit::Limiters }
  let(:divergence) { Gitlab::RackAttack::LabkitRateLimit::Divergence }

  # The matched rule names the throttle (minus the throttle_ prefix); the
  # middleware reconstructs the throttle name from it for the cohort lookup and the
  # 429 headers.
  let(:rule) { instance_double(Labkit::RateLimit::Rule, name: 'unauthenticated_web') }
  let(:result) { instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: rule) }
  let(:limiter) { instance_double(Labkit::RateLimit::Limiter, check: result) }

  # The middleware reads the registry only for the cohort (enforce gating); it builds
  # the request facts from ClassifiedRequest and the limiter matches against those.
  let(:entry) do
    registry::Entry.new(
      name: 'throttle_unauthenticated_web', limiter: registry::GENERAL, rule_name: 'unauthenticated_web',
      characteristics: [:ip], match: { path: registry::WEB_PATH_REGEX }, cohort: 2, definition: nil
    )
  end

  let(:throttle_data) { { 'throttle_unauthenticated_web' => { count: 5, limit: 100, period: 3600 } } }
  let(:app) { ->(_env) { [200, {}, ['ok']] } }
  let(:env) { Rack::MockRequest.env_for('/some/path').merge('rack.attack.throttle_data' => throttle_data) }
  let(:middleware) { described_class.new(app) }

  before do
    allow(registry).to receive_messages(cohorts: [2], all: { 'throttle_unauthenticated_web' => entry })
    allow(limiters).to receive(:all).and_return({ registry::GENERAL => limiter })
    allow(divergence).to receive(:record)

    stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: true)
  end

  context 'when a cohort shadow flag is on' do
    it 'passes the request facts to the limiter and the response through' do
      expect(limiter).to receive(:check)
        .with(hash_including(:ip, :requester_id, :requester_type, :runner_id, :aid, :path, :method))
        .and_return(result)

      status, _headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['ok'])
    end

    it 'compares labkit\'s block decision against the Rack::Attack data on the way back up' do
      # The request did not block (the :allow result), so there is no blocking
      # result; Divergence still receives the call and decides whether it is worth a
      # data point.
      expect(divergence).to receive(:record)
        .with(labkit_result: nil, rackattack_throttle_data: throttle_data)

      middleware.call(env)
    end

    it 'never returns a 429 when only the shadow flag is on (enforce off)' do
      allow(limiter).to receive(:check)
        .and_return(instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule))

      status, = middleware.call(env)

      expect(status).to eq(200)
    end

    context 'when another limiter returns an unmatched result carrying no rule' do
      # Production runs several limiters (rack_request, rack_request_protected_paths,
      # rack_request_incident_management); for any path at least one does not match and
      # returns an unmatched result whose rule is nil. enforced_response must not
      # dereference the rule on those results, or the shadow decision crashes and no
      # comparison is ever recorded (calls_total still fires, so the failure is silent).
      let(:unmatched_result) do
        instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: nil)
      end

      let(:unmatched_limiter) { instance_double(Labkit::RateLimit::Limiter, check: unmatched_result) }

      before do
        allow(limiters).to receive(:all).and_return(
          registry::GENERAL => limiter,
          registry::PROTECTED => unmatched_limiter
        )
      end

      it 'records the comparison without crashing on the nil-rule result', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)
        expect(divergence).to receive(:record)

        status, = middleware.call(env)

        expect(status).to eq(200)
      end
    end
  end

  context 'when the cohort enforce flag is on' do
    let(:info) do
      instance_double(
        Labkit::RateLimit::Result::Info,
        resolved_limit: 100, resolved_period: 3600, count: 101, remaining: 0, reset_at: Time.current
      )
    end

    before do
      stub_feature_flags(
        rate_limiter_use_labkit_rack_cohort_2: true,
        rate_limiter_use_labkit_rack_cohort_2_enforce: true
      )
    end

    context 'when labkit blocks and the rule\'s cohort enforces' do
      let(:result) do
        instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule, info: info)
      end

      it 'renders the legacy 429 and does not call the downstream app', :aggregate_failures do
        expect(app).not_to receive(:call)

        status, headers, body = middleware.call(env)

        expect(status).to eq(429)
        expect(headers).to include('Content-Type' => 'text/plain')
        expect(headers).to include('RateLimit-Limit', 'RateLimit-Remaining', 'RateLimit-Reset', 'Retry-After')
        expect(body).to eq([Gitlab::Throttle.rate_limiting_response_text])
      end

      it 'returns a 429 byte-identical to the legacy Rack::Attack responder' do
        freeze_time do
          legacy_request = ::Rack::Attack::Request.new(
            Rack::MockRequest.env_for('/some/path').merge(
              'rack.attack.matched' => 'throttle_unauthenticated_web',
              'rack.attack.match_data' => {
                discriminator: '1.2.3.4',
                count: info.count,
                period: info.resolved_period,
                limit: info.resolved_limit,
                epoch_time: Time.current.to_i
              }
            )
          )

          expect(middleware.call(env)).to eq(::Rack::Attack.throttled_responder.call(legacy_request))
        end
      end

      it 'does not record divergence, having short-circuited before the app' do
        expect(divergence).not_to receive(:record)

        middleware.call(env)
      end
    end

    context 'when labkit allows the request' do
      it 'falls through to Rack::Attack and records as in shadow mode' do
        expect(divergence).to receive(:record)

        status, = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'when labkit blocks but the rule\'s cohort does not enforce' do
      let(:other_entry) { entry.tap { |e| e.cohort = 1 } }
      let(:result) do
        instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule, info: info)
      end

      before do
        # cohort 1 has no enforce flag on, so the cohort-2-keyed rule does not match a
        # cohort whose enforce flag is set: the block is recorded, not enforced.
        allow(registry).to receive(:all).and_return({ 'throttle_unauthenticated_web' => other_entry })
        stub_feature_flags(
          rate_limiter_use_labkit_rack_cohort_1: true,
          rate_limiter_use_labkit_rack_cohort_2: true,
          rate_limiter_use_labkit_rack_cohort_2_enforce: true
        )
      end

      it 'does not enforce, and records the block as a comparison', :aggregate_failures do
        expect(divergence).to receive(:record)

        status, = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'when an unmatched (nil-rule) limiter is evaluated before the blocking one' do
      # find walks the results in limiter order; a nil-rule result ahead of the block
      # must be skipped, not dereferenced, or enforcement crashes and falls open to
      # legacy - silently enforcing nothing for that cohort.
      let(:result) do
        instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule, info: info)
      end

      let(:unmatched_result) do
        instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: nil)
      end

      let(:unmatched_limiter) { instance_double(Labkit::RateLimit::Limiter, check: unmatched_result) }

      before do
        allow(limiters).to receive(:all).and_return(
          registry::PROTECTED => unmatched_limiter,
          registry::GENERAL => limiter
        )
      end

      it 'skips the nil-rule result and still enforces the block', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        status, = middleware.call(env)

        expect(status).to eq(429)
      end
    end

    context 'when the block came from a web throttle frontend companion' do
      # The companion rule name (unauthenticated_web_frontend) is not itself a throttle
      # name, so it must resolve to its base throttle for both the enforce cohort and
      # the RateLimit-Name header - otherwise a cohort lookup miss would silently leave
      # frontend-API traffic unenforced.
      let(:rule) { instance_double(Labkit::RateLimit::Rule, name: 'unauthenticated_web_frontend') }
      let(:entry) do
        registry::Entry.new(
          name: 'throttle_unauthenticated_web', limiter: registry::GENERAL,
          rule_name: 'unauthenticated_web_frontend', characteristics: [:ip],
          match: { frontend: true }, cohort: 2, definition: nil
        )
      end

      let(:result) do
        instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule, info: info)
      end

      it 'enforces under the base throttle cohort and names the base throttle in the 429', :aggregate_failures do
        status, headers, = middleware.call(env)

        expect(status).to eq(429)
        expect(headers).to include('RateLimit-Name' => 'throttle_unauthenticated_web')
      end
    end
  end

  context 'when no cohort shadow flag is on' do
    before do
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: false)
    end

    it 'does not touch labkit and passes the response through' do
      expect(limiters).not_to receive(:all)

      status, = middleware.call(env)

      expect(status).to eq(200)
    end
  end

  describe 'fail-open and isolation' do
    it 'never lets a shadow error affect the response, and tracks it', :aggregate_failures do
      allow(limiter).to receive(:check).and_raise(StandardError, 'boom')
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))

      status, _headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['ok'])
    end

    it 'propagates the downstream application error rather than swallowing it' do
      boom = ->(_env) { raise IOError, 'app failed' }

      expect { described_class.new(boom).call(env) }.to raise_error(IOError, 'app failed')
    end

    it 'restores any throttle instrumentation a fact lookup touched', :request_store do
      # The shadow no longer writes the safelist itself (the requester discriminator
      # is computed from the auth primitive, not throttled_identifer), but the guard
      # is still defensive: a fact lookup that touched the instrumentation must not
      # leak into the real request.
      Gitlab::Instrumentation::Throttle.safelist = 'original'
      allow_next_instance_of(Gitlab::RackAttack::LabkitRateLimit::ClassifiedRequest) do |request|
        allow(request).to receive(:labkit_facts) do
          Gitlab::Instrumentation::Throttle.safelist = 'throttle_user_allowlist'
          {}
        end
      end

      middleware.call(env)

      expect(Gitlab::Instrumentation::Throttle.safelist).to eq('original')
    end
  end
end
