# frozen_string_literal: true

# Gitlab::Middleware::LabkitRackRateLimit runs the Labkit::RateLimit shadow in
# parallel with Rack::Attack, gated per cohort by the
# rate_limiter_use_labkit_rack_cohort_* feature flags. Feature flags default on
# in specs, which would run the shadow, building a second Rack::Attack::Request
# and re-resolving auth, in every request and feature spec.
#
# The shadow is opt-in in production (the flags start off and are flipped per
# cohort during rollout) and is exercised directly by its own specs, so default
# these flags off across the suite. This keeps unrelated specs deterministic and
# free of the shadow's side effects (a second request build and auth
# resolution). Specs that test the shadow re-enable the cohort flag they need,
# which overrides this default because it runs in a later before hook.
RSpec.configure do |config|
  config.before do
    rack_shadow_flags = Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.cohorts.flat_map do |cohort|
      [
        :"rate_limiter_use_labkit_rack_cohort_#{cohort}",
        :"rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce"
      ]
    end

    stub_feature_flags(rack_shadow_flags.index_with(false))
  end
end
