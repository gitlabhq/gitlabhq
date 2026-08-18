# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::LabkitRateLimit::Divergence, feature_category: :rate_limiting do
  let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

  before do
    allow(Gitlab::Metrics).to receive(:counter).and_call_original
    allow(Gitlab::Metrics).to receive(:counter)
      .with(:gitlab_rate_limiter_labkit_rack_shadow_total, anything, anything)
      .and_return(counter)
    travel_to(Time.at(1800).utc) # mid-window for period 3600
  end

  # A Rack::Attack annotation for one throttle. count > limit means it throttled.
  def rackattack_data(name, count:, limit: 100, period: 3600, discriminator: '1.2.3.4')
    { name => { discriminator: discriminator, count: count, limit: limit, period: period } }
  end

  def labkit_result(action:, error: false, rule_name: 'authenticated_api', period: 3600, count: 101.0, limit: 100)
    rule = instance_double(Labkit::RateLimit::Rule, name: rule_name)
    info = instance_double(
      Labkit::RateLimit::Result::Info, resolved_period: period, count: count, resolved_limit: limit
    )
    instance_double(Labkit::RateLimit::Result, action: action, error?: error, rule: rule, info: info)
  end

  describe '.record' do
    it 'records a match when both stacks block, labelled by the labkit rule' do
      expect(counter).to receive(:increment).with(throttle: 'throttle_authenticated_api', agreement: :match,
        boundary: false)

      described_class.record(
        labkit_result: labkit_result(action: :block),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101)
      )
    end

    it 'records a divergence when labkit blocks but Rack::Attack did not' do
      expect(counter).to receive(:increment).with(throttle: 'throttle_authenticated_api', agreement: :diverge,
        boundary: false)

      described_class.record(
        labkit_result: labkit_result(action: :block),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 5)
      )
    end

    it 'records a divergence labelled by the Rack::Attack throttle when only it blocked' do
      expect(counter).to receive(:increment).with(throttle: 'throttle_authenticated_api', agreement: :diverge,
        boundary: false)

      described_class.record(
        labkit_result: nil,
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101)
      )
    end

    it 'does not record when neither stack blocked, keeping the diverge signal sparse' do
      expect(counter).not_to receive(:increment)

      described_class.record(
        labkit_result: labkit_result(action: :allow),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 5)
      )
    end

    it 'skips a fail-open labkit result, which is not a real disagreement' do
      expect(counter).not_to receive(:increment)

      described_class.record(
        labkit_result: labkit_result(action: :allow, error: true),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101)
      )
    end

    it 'tags a window-edge disagreement as boundary noise' do
      travel_to(Time.at(3600).utc) # elapsed 0 -> within BOUNDARY_NOISE_SECONDS of the edge

      expect(counter).to receive(:increment).with(throttle: 'throttle_authenticated_api', agreement: :diverge,
        boundary: true)

      described_class.record(
        labkit_result: labkit_result(action: :block),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 5)
      )
    end

    it 'does not raise when the period is zero' do
      expect do
        described_class.record(
          labkit_result: nil,
          rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101, period: 0)
        )
      end.not_to raise_error
    end
  end

  describe 'sampled divergence logging' do
    let(:facts) do
      {
        ip: '1.2.3.4', requester_id: '42', requester_type: 'user', runner_id: nil,
        path: '/api/v4/projects', method: 'GET'
      }
    end

    it 'logs both stacks\' verdicts, counters, and discriminators for a divergence' do
      blocking = labkit_result(action: :block, count: 101.0, limit: 100)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        Labkit::Fields::LOG_MESSAGE => 'Labkit rack shadow divergence',
        Labkit::Fields::CLASS_NAME => described_class.name,
        Labkit::Fields::REMOTE_IP => '1.2.3.4',
        Labkit::Fields::HTTP_METHOD => 'GET',
        throttle: 'throttle_authenticated_api',
        labkit_blocked: true,
        rackattack_blocked: false,
        labkit_rules: [{ rule: 'authenticated_api', action: 'block', count: 101.0, limit: 100 }],
        rackattack_throttles: [
          { throttle: 'throttle_authenticated_api', discriminator: 'user:42', count: 5, limit: 100 }
        ],
        requester_type: 'user',
        requester_id: '42',
        runner_id: nil,
        path: '/api/v4/projects'
      )

      described_class.record(
        labkit_result: blocking,
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 5, discriminator: 'user:42'),
        labkit_results: [blocking],
        facts: facts
      )
    end

    it 'logs where labkit routed the request when only Rack::Attack blocked' do
      matched_allow = labkit_result(action: :allow, count: 5.0, limit: 100)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          labkit_blocked: false,
          rackattack_blocked: true,
          labkit_rules: [{ rule: 'authenticated_api', action: 'allow', count: 5.0, limit: 100 }]
        )
      )

      described_class.record(
        labkit_result: nil,
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101),
        labkit_results: [matched_allow],
        facts: facts
      )
    end

    it 'logs a matched skip rule with nil counters, since a skip performs no Redis operation' do
      skip_rule = instance_double(Labkit::RateLimit::Rule, name: 'runner_jobs')
      skipped = instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: skip_rule, info: nil)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(labkit_rules: [{ rule: 'runner_jobs', action: 'allow', count: nil, limit: nil }])
      )

      described_class.record(
        labkit_result: nil,
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101),
        labkit_results: [skipped],
        facts: facts
      )
    end

    it 'drops unmatched limiter results, which carry no rule to report' do
      unmatched = instance_double(Labkit::RateLimit::Result, action: :allow, error?: false, rule: nil)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(hash_including(labkit_rules: []))

      described_class.record(
        labkit_result: nil,
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101),
        labkit_results: [unmatched],
        facts: facts
      )
    end

    it 'does not log an agreement, only divergences carry diagnostic value' do
      expect(Gitlab::AppJsonLogger).not_to receive(:info)

      described_class.record(
        labkit_result: labkit_result(action: :block),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 101),
        facts: facts
      )
    end

    it 'does not log when the sampling flag is disabled' do
      stub_feature_flags(log_labkit_rack_divergence: false)

      expect(Gitlab::AppJsonLogger).not_to receive(:info)

      described_class.record(
        labkit_result: labkit_result(action: :block),
        rackattack_throttle_data: rackattack_data('throttle_authenticated_api', count: 5),
        facts: facts
      )
    end
  end
end
