# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::LabkitRackRateLimit, feature_category: :rate_limiting do
  let(:registry) { Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry }
  let(:limiters) { Gitlab::RackAttack::LabkitRateLimit::Limiters }
  let(:plan_rules) { Gitlab::RackAttack::LabkitRateLimit::PlanRules }

  # The matched rule names the throttle (minus the throttle_ prefix); the
  # middleware reconstructs the throttle name from it for the cohort lookup and the
  # 429 headers.
  let(:rule) { instance_double(Labkit::RateLimit::Rule, name: 'unauthenticated_web') }
  let(:result) do
    instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: rule, evaluations: [])
  end

  let(:limiter) { instance_double(Labkit::RateLimit::Limiter, check: result) }

  # The middleware reads the registry only for the cohort (enforce gating); it builds
  # the request facts from ClassifiedRequest and the limiter matches against those.
  let(:entry) do
    registry::Entry.new(
      name: 'throttle_unauthenticated_web', limiter: registry::GENERAL, rule_name: 'unauthenticated_web',
      characteristics: [:ip], match: { web_or_frontend: true }, cohort: 2, definition: nil
    )
  end

  let(:app) { ->(_env) { [200, {}, ['ok']] } }
  let(:env) { Rack::MockRequest.env_for('/some/path') }
  let(:middleware) { described_class.new(app) }

  before do
    allow(registry).to receive_messages(cohorts: [2], all: { 'throttle_unauthenticated_web' => entry })
    allow(limiters).to receive(:all).and_return({ registry::GENERAL => limiter })

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

    it 'leaves the downstream response untouched on the way back up', :aggregate_failures do
      # Enforce is off, so the shadow observes only: no 429, and no proactive headers
      # (Rack::Attack still enforces and RackAttackHeaders still builds those).
      status, headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['ok'])
      expect(headers).not_to include('RateLimit-Name')
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
      # dereference the rule on those results, or the shadow decision crashes and
      # falls open silently.
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

      it 'runs the shadow without crashing on the nil-rule result', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

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

      it 'short-circuits, so nothing downstream reaches the response' do
        header_setting_app = ->(_env) { [200, { 'X-Downstream' => 'yes' }, ['ok']] }

        _status, headers, = described_class.new(header_setting_app).call(env)

        expect(headers).not_to include('X-Downstream')
      end
    end

    context 'when labkit allows the request' do
      it 'falls through to Rack::Attack rather than short-circuiting', :aggregate_failures do
        expect(app).to receive(:call).and_call_original

        status, = middleware.call(env)

        expect(status).to eq(200)
      end
    end

    context 'when labkit blocks but the rule\'s cohort does not enforce' do
      let(:other_entry) { entry.tap { |e| e.cohort = 1 } }
      let(:result) do
        instance_double(
          Labkit::RateLimit::Result, action: :block, error?: false, rule: rule, info: info, evaluations: []
        )
      end

      before do
        # cohort 1 has no enforce flag on, so the cohort-2-keyed rule does not match a
        # cohort whose enforce flag is set: the block is observed, not enforced.
        allow(registry).to receive(:all).and_return({ 'throttle_unauthenticated_web' => other_entry })
        stub_feature_flags(
          rate_limiter_use_labkit_rack_cohort_1: true,
          rate_limiter_use_labkit_rack_cohort_2: true,
          rate_limiter_use_labkit_rack_cohort_2_enforce: true
        )
      end

      it 'does not enforce, letting the request through to Rack::Attack', :aggregate_failures do
        expect(app).to receive(:call).and_call_original

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
  end

  describe 'proactive RateLimit-* headers once labkit fully enforces' do
    let(:info) do
      Labkit::RateLimit::Result::Info.new(
        resolved_limit: 100, resolved_period: 60, count: 5.0, remaining: 95.0, reset_at: Time.current
      )
    end

    let(:evaluation) { Labkit::RateLimit::Result::Evaluation.new(rule: rule, exceeded: false, info: info) }

    let(:result) do
      instance_double(
        Labkit::RateLimit::Result, action: :allow, error?: false, rule: rule, evaluations: [evaluation]
      )
    end

    before do
      stub_feature_flags(
        rate_limiter_use_labkit_rack_cohort_2: true,
        rate_limiter_use_labkit_rack_cohort_2_enforce: true
      )
    end

    it 'adds the counted throttle\'s headers to the response', :aggregate_failures do
      status, headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['ok'])
      expect(headers).to include(
        'RateLimit-Name' => 'throttle_unauthenticated_web',
        'RateLimit-Limit' => '100',
        'RateLimit-Observed' => '5',
        'RateLimit-Remaining' => '95'
      )
      expect(headers).to include('RateLimit-Reset')
      expect(headers).not_to include('Retry-After', 'RateLimit-ResetTime')
    end

    it 'produces headers byte-identical to the legacy RackAttackHeaders output' do
      freeze_time do
        legacy_headers = Gitlab::RackAttack::RequestThrottleData.from_rack_attack(
          'throttle_unauthenticated_web',
          { discriminator: '1.2.3.4', count: 5, period: 60, limit: 100, epoch_time: Time.current.to_i }
        ).common_response_headers

        _status, headers, = middleware.call(env)

        expect(headers).to include(legacy_headers)
      end
    end

    it 'still adds headers to non-2xx responses, as RackAttackHeaders did' do
      not_found = ->(_env) { [404, {}, ['not found']] }

      _status, headers, = described_class.new(not_found).call(env)

      expect(headers['RateLimit-Name']).to eq('throttle_unauthenticated_web')
    end

    it 'leaves an app-rendered 429 untouched', :aggregate_failures do
      app_throttled = ->(_env) { [429, { 'Content-Type' => 'text/plain' }, ['app throttled']] }

      status, headers, = described_class.new(app_throttled).call(env)

      expect(status).to eq(429)
      expect(headers).not_to include('RateLimit-Name')
    end

    context 'when several limiters counted the request' do
      let(:protected_rule) { instance_double(Labkit::RateLimit::Rule, name: 'unauthenticated_protected_paths') }

      let(:protected_entry) do
        registry::Entry.new(
          name: 'throttle_unauthenticated_protected_paths', limiter: registry::PROTECTED,
          rule_name: 'unauthenticated_protected_paths', characteristics: [:ip],
          match: { protected_path: true }, cohort: 2, definition: nil
        )
      end

      let(:protected_info) do
        Labkit::RateLimit::Result::Info.new(
          resolved_limit: 10, resolved_period: 60, count: 8.0, remaining: 2.0, reset_at: Time.current
        )
      end

      let(:protected_evaluation) do
        Labkit::RateLimit::Result::Evaluation.new(rule: protected_rule, exceeded: false, info: protected_info)
      end

      let(:protected_result) do
        instance_double(
          Labkit::RateLimit::Result, action: :allow, error?: false, rule: protected_rule,
          evaluations: [protected_evaluation]
        )
      end

      before do
        allow(registry).to receive(:all).and_return(
          'throttle_unauthenticated_web' => entry,
          'throttle_unauthenticated_protected_paths' => protected_entry
        )
        allow(limiters).to receive(:all).and_return(
          registry::GENERAL => limiter,
          registry::PROTECTED => instance_double(Labkit::RateLimit::Limiter, check: protected_result)
        )
      end

      it 'reports the most constraining evaluation (fewest remaining)', :aggregate_failures do
        _status, headers, = middleware.call(env)

        expect(headers['RateLimit-Name']).to eq('throttle_unauthenticated_protected_paths')
        expect(headers['RateLimit-Remaining']).to eq('2')
      end
    end

    context 'when a dry-run throttle counted the request over its limit' do
      # A :log rule never blocks, but Rack::Attack's Track wrote throttle_data all
      # the same, so a dry-run throttle kept feeding the proactive headers.
      let(:rule) { instance_double(Labkit::RateLimit::Rule, name: 'unauthenticated_web', action: :log) }

      let(:info) do
        Labkit::RateLimit::Result::Info.new(
          resolved_limit: 100, resolved_period: 60, count: 105.0, remaining: 0.0, reset_at: Time.current
        )
      end

      let(:evaluation) { Labkit::RateLimit::Result::Evaluation.new(rule: rule, exceeded: true, info: info) }

      it 'reports the exhausted quota without blocking, as Rack::Attack track did', :aggregate_failures do
        status, headers, = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).to include(
          'RateLimit-Name' => 'throttle_unauthenticated_web',
          'RateLimit-Observed' => '105',
          'RateLimit-Remaining' => '0'
        )
      end
    end

    context 'when no rule counted the request (bypassed, skipped, or unmatched)' do
      let(:result) do
        instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: nil, evaluations: [])
      end

      it 'adds no headers, matching the legacy safelisted/skipped behavior' do
        _status, headers, = middleware.call(env)

        expect(headers).not_to include('RateLimit-Name')
      end
    end

    context 'when the counted rule resolves to no registry entry' do
      let(:rule) { instance_double(Labkit::RateLimit::Rule, name: 'unknown_rule') }

      it 'adds no headers and tracks no error', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        status, headers, = middleware.call(env)

        expect(status).to eq(200)
        expect(headers).not_to include('RateLimit-Name')
      end
    end

    context 'when a cohort does not yet enforce' do
      before do
        stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2_enforce: false)
      end

      it 'adds no headers - Rack::Attack still enforces and RackAttackHeaders builds them' do
        _status, headers, = middleware.call(env)

        expect(headers).not_to include('RateLimit-Name')
      end
    end

    it 'fails open when header generation errors, leaving the response intact', :aggregate_failures do
      allow(Gitlab::RackAttack::RequestThrottleData)
        .to receive(:from_labkit_result).and_raise(StandardError, 'boom')
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))

      status, headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(['ok'])
      expect(headers).not_to include('RateLimit-Name')
    end
  end

  context 'when no cohort shadow flag is on and no plan limit is in play' do
    before do
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: false)
    end

    it 'does not touch labkit and passes the response through' do
      expect(limiters).not_to receive(:all)

      status, = middleware.call(env)

      expect(status).to eq(200)
    end
  end

  # PlanRules is stubbed rather than its flags, which are EE-only definitions.
  context 'when no cohort shadow flag is on but a plan limit is in play' do
    before do
      stub_feature_flags(rate_limiter_use_labkit_rack_cohort_2: false)
      allow(plan_rules).to receive(:active?).and_return(true)
    end

    it 'still runs the rules over the request facts' do
      expect(limiter).to receive(:check)
        .with(hash_including(:ip, :requester_id, :requester_type, :runner_id, :aid, :path, :method))
        .and_return(result)

      status, = middleware.call(env)

      expect(status).to eq(200)
    end

    it 'does not enforce, since no cohort enforces the blocked rule' do
      allow(limiter).to receive(:check)
        .and_return(instance_double(Labkit::RateLimit::Result, action: :block, error?: false, rule: rule))

      status, = middleware.call(env)

      expect(status).to eq(200)
    end

    # The state after the cohort flags are deleted.
    context 'when the registry declares no cohorts at all' do
      before do
        allow(registry).to receive(:cohorts).and_return([])
      end

      it 'runs the rules without reading a cohort flag', :aggregate_failures do
        expect(registry).not_to receive(:shadow_enabled?)
        expect(limiter).to receive(:check).and_return(result)

        status, = middleware.call(env)

        expect(status).to eq(200)
      end
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
