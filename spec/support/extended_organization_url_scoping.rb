# frozen_string_literal: true

# Feature specs run against the non-default common-org, whose paths are
# scoped, while every spec visits and asserts unscoped URLs. The browser sends
# X-GitLab-Organization-ID on API calls, so with extended_organization_url_scoping
# on (flags default on in specs) the server answers with /o/common-org/ paths
# that the spec-side helpers never produce. Keep the flag off for feature
# specs, matching its production default, until feature specs run fully
# scoped: https://gitlab.com/gitlab-org/gitlab/-/issues/605262
RSpec.configure do |config|
  config.before(:each, type: :feature) do
    stub_feature_flags(extended_organization_url_scoping: false)
  end
end
