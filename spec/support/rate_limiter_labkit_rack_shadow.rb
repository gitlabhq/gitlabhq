# frozen_string_literal: true

# Keeps every PlanRules flag off across the suite, which specs otherwise run with on.
# It does not stop the labkit rack middleware running, which is unconditional now:
# what depends on this is the specs asserting PlanRules is inactive. Removal is
# tracked in https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/29739
RSpec.configure do |config|
  config.before do
    stub_feature_flags(Gitlab::RateLimit::PlanRules.flags.index_with(false))
  end
end
