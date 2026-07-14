# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits,
  feature_category: :system_access do
  describe 'registry coverage' do
    # The labkit adapter is the only rate-limiting path; there is no legacy
    # fallback. A rate_limits key with no registry entry would not have a Labkit
    # rule to route through. This guard fails
    # loudly when a new key is added to ApplicationRateLimiter.rate_limits
    # without a matching SupportedRateLimits entry.
    it 'registers every ApplicationRateLimiter.rate_limits key' do
      rate_limit_keys = ::Gitlab::ApplicationRateLimiter.rate_limits.keys.to_set
      registered = described_class.all.keys.to_set

      unregistered = rate_limit_keys - registered

      expect(unregistered).to be_empty,
        "These ApplicationRateLimiter.rate_limits keys have no Labkit::RateLimit registry " \
          "entry, so they would not be rate limited: #{unregistered.to_a.sort.join(', ')}. " \
          "Add an entry in SupportedRateLimits (or its EE counterpart)."
    end
  end

  describe 'limit/period parity with the legacy rate_limits hash' do
    # The registry now carries each key's limit/period, and the
    # rate_limiter_resolve_limits_from_registry flag selects whether
    # ApplicationRateLimiter.threshold/interval (and therefore the labkit
    # adapter) resolve from this registry (flag on) or from the legacy
    # ApplicationRateLimiter.rate_limits hash (flag off). For the flag to be a
    # safe, value-preserving switch, both sources must resolve to identical
    # values for every key. The registry-coverage guard only checks key
    # presence, not values, so this is the spec that catches a mistranscribed
    # limit or period.
    #
    # Iterates the live rate_limits map: under EE it also covers the EE
    # overrides and additions, without naming any EE-only key here (so the
    # spec stays correct under FOSS_ONLY).
    it 'resolves identical threshold and interval whether the flag is on or off', :aggregate_failures do
      arl = ::Gitlab::ApplicationRateLimiter

      # Make every application setting return a value derived from its own name.
      # A registry callable that reads a *different* setting than its rate_limits
      # counterpart (e.g. a sibling like users_api_limit_gpg_key vs _gpg_keys that
      # shares a default) then resolves to a different number, so the eq assertions
      # below catch the mistranscription. Static-integer entries are unaffected:
      # both sides return the literal and never touch settings.
      fake_settings = Class.new do
        def method_missing(name, *)
          name.to_s.hash.abs
        end

        def respond_to_missing?(*)
          true
        end
      end.new
      allow(::Gitlab::CurrentSettings).to receive(:current_application_settings).and_return(fake_settings)

      arl.rate_limits.each_key do |key|
        stub_feature_flags(rate_limiter_resolve_limits_from_registry: false)
        legacy_threshold = arl.threshold(key)
        legacy_interval = arl.interval(key)

        stub_feature_flags(rate_limiter_resolve_limits_from_registry: true)
        registry_threshold = arl.threshold(key)
        registry_interval = arl.interval(key)

        expect(registry_threshold).to eq(legacy_threshold),
          "threshold mismatch for #{key}: registry=#{registry_threshold} legacy=#{legacy_threshold}"
        expect(registry_interval).to eq(legacy_interval),
          "interval mismatch for #{key}: registry=#{registry_interval} legacy=#{legacy_interval}"
      end
    end
  end
end
