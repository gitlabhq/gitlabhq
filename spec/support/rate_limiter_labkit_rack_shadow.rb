# frozen_string_literal: true

# Either flag family would otherwise start the labkit rack shadow in unrelated specs,
# building a second request and re-resolving auth: the migration cohorts default on
# everywhere, PlanRules wherever a spec also stubs SaaS on. The shadow's own specs
# re-enable what they need in a later hook, and PlanRules.flags is empty under FOSS.
RSpec.configure do |config|
  config.before do
    rack_shadow_flags = Gitlab::RackAttack::LabkitRateLimit::ThrottleRegistry.cohorts.flat_map do |cohort|
      [
        :"rate_limiter_use_labkit_rack_cohort_#{cohort}",
        :"rate_limiter_use_labkit_rack_cohort_#{cohort}_enforce"
      ]
    end

    rack_shadow_flags += Gitlab::RackAttack::LabkitRateLimit::PlanRules.flags

    stub_feature_flags(rack_shadow_flags.index_with(false))
  end
end
