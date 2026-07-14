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
  def rackattack_data(name, count:, limit: 100, period: 3600)
    { name => { count: count, limit: limit, period: period } }
  end

  def labkit_result(action:, error: false, rule_name: 'authenticated_api', period: 3600)
    rule = instance_double(Labkit::RateLimit::Rule, name: rule_name)
    info = instance_double(Labkit::RateLimit::Result::Info, resolved_period: period)
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
end
