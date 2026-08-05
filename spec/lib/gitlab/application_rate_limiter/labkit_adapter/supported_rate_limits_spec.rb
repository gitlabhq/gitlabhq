# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits,
  :clean_gitlab_redis_rate_limiting, feature_category: :system_access do
  let(:cost_mode_keys) do
    %i[
      main_db_duration_limit_per_worker
      ci_db_duration_limit_per_worker
      sec_db_duration_limit_per_worker
    ]
  end

  let(:threshold_from_caller_keys) do
    %i[
      web_hook_calls
      web_hook_calls_low
      web_hook_calls_mid
    ]
  end

  let(:call_site_less_keys) do
    %i[
      code_suggestions_x_ray_dependencies
      code_suggestions_x_ray_scan
    ]
  end

  describe 'registry coverage' do
    it 'builds limiters for every registered rule' do
      expect(described_class.all.keys).to match_array(described_class.rules.keys)
    end

    it 'registers valid labkit rate-limit entries', :aggregate_failures do
      expect(described_class.all).not_to be_empty

      described_class.all.to_a.each do |key, limiter|
        rule = described_class.rule_for(key)

        expect(limiter).to be_a(::Labkit::RateLimit::Limiter), "#{key} limiter must be a Labkit limiter"
        expect(rule).to be_a(::Labkit::RateLimit::Rule), "#{key} rule must be a Labkit rule"
        expect(rule.name).not_to be_empty, "#{key} rule name must not be empty"
        expect(rule.name).to start_with('limit_'), "#{key} rule name must start with limit_"
        expect(rule.characteristics).to be_an(Array), "#{key} characteristics must be an Array"
        expect(rule.characteristics).not_to be_empty, "#{key} characteristics must not be empty"
        expect(rule.characteristics).to all(be_a(Symbol)), "#{key} characteristics must be Symbols"
        expect(rule.action).to eq(:limit), "#{key} action must be :limit"
      end
    end

    it 'requires limit and period unless the entry documents why they are caller-supplied', :aggregate_failures do
      described_class.rules.to_a.each do |key, rule|
        if cost_mode_keys.include?(key)
          expect(described_class.cost_mode?(key)).to be(true), "#{key} must be marked as cost_mode"
          next
        end

        if threshold_from_caller_keys.include?(key)
          expect(rule.limit).to respond_to(:call), "#{key} must define a caller-aware limit"
          expect(rule.period).to be_present, "#{key} must define a period"
          expect(described_class.cost_mode?(key)).to be(false),
            "#{key} must not be both threshold-from-caller and cost_mode"
          next
        end

        next if call_site_less_keys.include?(key)

        expect(rule.limit).to be_present,
          "#{key} must define a limit unless it is an explicit special case"
        expect(rule.period).to be_present,
          "#{key} must define a period unless it is an explicit special case"
      end
    end
  end

  describe '.limiter_for' do
    it 'returns a labkit limiter for a registered key' do
      expect(described_class.limiter_for(:pipelines_create)).to be_a(::Labkit::RateLimit::Limiter)
    end

    it 'caches the limiter for a registered key' do
      limiter = described_class.limiter_for(:pipelines_create)

      expect(described_class.limiter_for(:pipelines_create)).to be(limiter)
    end

    it 'raises KeyError for an unregistered key' do
      expect { described_class.limiter_for(:not_a_registered_key) }.to raise_error(KeyError)
    end

    it 'builds a limiter that can check using the registered rule' do
      user = build_stubbed(:user)
      limiter = described_class.limiter_for(:users_get_by_id)

      allow(Gitlab::CurrentSettings.current_application_settings)
        .to receive(:users_get_by_id_limit).and_return(1)

      expect(limiter.check({ user: user.id }).exceeded?).to be(false)
      expect(limiter.check({ user: user.id }).exceeded?).to be(true)
    end
  end

  describe '.accepts_context?' do
    it 'returns false for fixed values' do
      expect(described_class.accepts_context?(1)).to be(false)
    end

    it 'returns false for zero-arity callables' do
      expect(described_class.accepts_context?(-> { 1 })).to be(false)
    end

    it 'returns true for one-arity callables' do
      expect(described_class.accepts_context?(->(_ctx) { 1 })).to be(true)
    end

    it 'returns false for variadic callables' do
      expect(described_class.accepts_context?(->(*_ctx) { 1 })).to be(false)
    end
  end

  describe '.limit_for' do
    let(:rule) do
      ::Labkit::RateLimit::Rule.new(
        name: 'limit_configured_limit',
        characteristics: %i[user],
        limit: ->(ctx) { ctx&.dig(:threshold) || 3 },
        period: ->(ctx) { ctx&.dig(:interval) || 1.minute },
        action: :limit
      )
    end

    before do
      allow(described_class).to receive(:rule_for).with(:configured_limit).and_return(rule)
    end

    it 'resolves registry callables' do
      expect(described_class.limit_for(:configured_limit)).to eq(3)
    end

    it 'prefers caller context overrides' do
      expect(described_class.limit_for(:configured_limit, context: { threshold: 5 })).to eq(5)
    end

    it 'preserves zero caller overrides' do
      expect(described_class.limit_for(:configured_limit, context: { threshold: 0 })).to eq(0)
    end
  end

  describe '.period_for' do
    let(:configured_period_rule) do
      ::Labkit::RateLimit::Rule.new(
        name: 'limit_configured_period',
        characteristics: %i[user],
        limit: ->(ctx) { ctx&.dig(:threshold) || 1 },
        period: ->(ctx) { ctx&.dig(:interval) || 2.minutes },
        action: :limit
      )
    end

    let(:caller_period_rule) do
      ::Labkit::RateLimit::Rule.new(
        name: 'limit_caller_period',
        characteristics: %i[user],
        limit: ->(ctx) { ctx&.dig(:threshold) || 1 },
        period: ->(ctx) { ctx&.dig(:interval) || 0 },
        action: :limit
      )
    end

    before do
      allow(described_class).to receive(:rule_for).with(:configured_period).and_return(configured_period_rule)
      allow(described_class).to receive(:rule_for).with(:caller_period).and_return(caller_period_rule)
    end

    it 'resolves registry callables' do
      expect(described_class.period_for(:configured_period)).to eq(2.minutes)
    end

    it 'prefers caller context overrides' do
      expect(described_class.period_for(:configured_period, context: { interval: 5 })).to eq(5)
    end

    it 'preserves zero caller overrides' do
      expect(described_class.period_for(:configured_period, context: { interval: 0 })).to eq(0)
    end

    it 'resolves caller-supplied periods for entries without a registry period' do
      expect(described_class.period_for(:caller_period, context: { interval: 10 })).to eq(10)
    end

    it 'falls back to zero for entries without a registry period or caller override' do
      expect(described_class.period_for(:caller_period)).to eq(0)
    end
  end
end
