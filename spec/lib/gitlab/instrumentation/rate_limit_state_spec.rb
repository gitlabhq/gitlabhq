# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::RateLimitState, :request_store, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax

  let(:limiter) { 'rack_request' }

  let(:info) do
    Labkit::RateLimit::Result::Info.new(
      resolved_limit: 100, resolved_period: 60, count: 101, remaining: 0, reset_at: Time.current
    )
  end

  def build_rule(name, action: :limit, ban_for: nil, limit: 100)
    Labkit::RateLimit::Rule.new(
      name: name, limit: limit, period: 60, characteristics: [:ip], action: action, ban_for: ban_for
    )
  end

  def build_result(rule, exceeded: false)
    evaluation = Labkit::RateLimit::Result::Evaluation.new(rule: rule, exceeded: exceeded, info: info)

    Labkit::RateLimit::Result.new.add_evaluation(evaluation)
  end

  describe '.track' do
    context 'with a counted rule' do
      where(:action, :ban_for, :exceeded, :expected) do
        :limit | nil  | false | 'allow'
        :limit | nil  | true  | 'block'
        :log   | nil  | true  | 'log'
        :limit | 3600 | true  | 'banned'
      end

      with_them do
        it 'reports the value the rule_evaluations_total metric would report' do
          rule = build_rule('unauthenticated_web', action: action, ban_for: ban_for)

          described_class.track(limiter => build_result(rule, exceeded: exceeded))

          expect(described_class.payload).to eq(
            described_class::STATE => ["rack_request:unauthenticated_web:#{expected}"]
          )
        end
      end
    end

    it 'reports a bypass, which counts nothing, as skipped' do
      rule = build_rule('bypass_header', action: :skip, limit: 0)

      described_class.track(limiter => Labkit::RateLimit::Result.new.skip!(rule))

      expect(described_class.payload).to eq(
        described_class::STATE => ['rack_request:bypass_header:skip']
      )
    end

    context 'when a claim rule terminated the check' do
      # Every registry throttle follows its counting rule with a terminating
      # :skip claim, which becomes Result#rule. Reporting only that would name
      # the claim and hide the rule that counted.
      let(:claim) { build_rule('unauthenticated_web_claim', action: :skip, limit: 0) }

      it 'reports the rule that counted, then the rule that ended the check' do
        result = build_result(build_rule('unauthenticated_web')).skip!(claim)

        described_class.track(limiter => result)

        expect(described_class.payload).to eq(
          described_class::STATE => [
            'rack_request:unauthenticated_web:allow',
            'rack_request:unauthenticated_web_claim:skip'
          ]
        )
      end

      it 'still reports an exceeded log rule as log' do
        # A :log rule does not terminate the check, so in observe mode the claim
        # always lands behind it and Result#exceeded? goes false once skipped.
        result = build_result(build_rule('unauthenticated_web_log', action: :log), exceeded: true)
          .skip!(claim)

        described_class.track(limiter => result)

        expect(described_class.payload).to eq(
          described_class::STATE => [
            'rack_request:unauthenticated_web_log:log',
            'rack_request:unauthenticated_web_claim:skip'
          ]
        )
      end
    end

    it 'names the limiter, so one rule name on two limiters stays distinct' do
      # Every limiter builds the same synthetic rules, so the rule name alone
      # does not say which limiter reported it.
      bypass = build_rule('bypass_header', action: :skip, limit: 0)

      described_class.track(
        'rack_request' => Labkit::RateLimit::Result.new.skip!(bypass),
        'rack_request_protected_paths' => Labkit::RateLimit::Result.new.skip!(bypass)
      )

      expect(described_class.payload).to eq(
        described_class::STATE => [
          'rack_request:bypass_header:skip',
          'rack_request_protected_paths:bypass_header:skip'
        ]
      )
    end

    it 'keeps one entry per limiter that reported a rule' do
      described_class.track(
        'rack_request' => build_result(build_rule('unauthenticated_web'), exceeded: true),
        'rack_request_protected_paths' => build_result(build_rule('protected_paths'))
      )

      expect(described_class.payload).to eq(
        described_class::STATE => [
          'rack_request:unauthenticated_web:block',
          'rack_request_protected_paths:protected_paths:allow'
        ]
      )
    end

    # A plan rule carries no claim, so it counts alongside the registry throttle
    # on the same limiter. Reporting only the most constraining would name one
    # and hide the other, which is the question the field exists to answer.
    it 'reports every rule that counted in one limiter, not only the strictest' do
      tiered = Labkit::RateLimit::Result::Evaluation.new(
        rule: build_rule('unauthenticated_traffic_per_ip_log', action: :log), exceeded: true, info: info
      )
      registry = Labkit::RateLimit::Result::Evaluation.new(
        rule: build_rule('unauthenticated_web'), exceeded: false, info: info
      )
      result = Labkit::RateLimit::Result.new.add_evaluation(tiered).add_evaluation(registry)

      described_class.track(limiter => result)

      expect(described_class.payload).to eq(
        described_class::STATE => [
          'rack_request:unauthenticated_traffic_per_ip_log:log',
          'rack_request:unauthenticated_web:allow'
        ]
      )
    end

    it 'drops an unmatched result, which carries no rule' do
      described_class.track(limiter => Labkit::RateLimit::Result.new)

      expect(described_class.payload).to eq({})
    end

    it 'drops a fail-open error result' do
      described_class.track(limiter => Labkit::RateLimit::Result.error)

      expect(described_class.payload).to eq({})
    end

    it 'does nothing without an active request store' do
      allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(false)

      described_class.track(limiter => build_result(build_rule('unauthenticated_web')))

      expect(described_class.payload).to eq({})
    end
  end

  describe '.payload' do
    it 'is empty when nothing was tracked' do
      expect(described_class.payload).to eq({})
    end
  end
end
