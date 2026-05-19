# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits,
  feature_category: :system_access do
  describe 'feature flag YAML coverage' do
    def yaml_exists?(flag_name)
      %w[config/feature_flags/wip ee/config/feature_flags/wip].any? do |dir|
        Rails.root.join(dir, "#{flag_name}.yml").exist?
      end
    end

    it 'has a use_labkit / _enforce YAML pair for every cohort-wide flag_scope' do
      scopes = described_class.all.values.filter_map { |entry| entry[:flag_scope] }.uniq

      missing = scopes.flat_map do |scope|
        ["rate_limiter_use_labkit_#{scope}", "rate_limiter_use_labkit_#{scope}_enforce"]
          .reject { |name| yaml_exists?(name) }
      end

      expect(missing).to be_empty,
        "Missing FF YAMLs for cohort-wide flag_scopes: #{missing.join(', ')}"
    end

    it 'has a use_labkit / _enforce YAML pair for every per-key (cohort 1) entry' do
      per_key = described_class.all.reject { |_, entry| entry[:flag_scope] }

      missing = per_key.keys.flat_map do |key|
        ["rate_limiter_use_labkit_#{key}", "rate_limiter_use_labkit_#{key}_enforce"]
          .reject { |name| yaml_exists?(name) }
      end

      expect(missing).to be_empty,
        "Missing FF YAMLs for per-key entries: #{missing.join(', ')}"
    end
  end
end
