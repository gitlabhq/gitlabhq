# frozen_string_literal: true

# Feature specs run against the non-default common-org, whose paths are
# scoped, while every spec visits and asserts unscoped URLs. The browser sends
# X-GitLab-Organization-ID on API calls, so the server would answer with
# /o/common-org/ paths that the spec-side helpers never produce. Keep the
# header fallback off for feature specs until they run fully scoped:
# https://gitlab.com/gitlab-org/gitlab/-/issues/605262
RSpec.configure do |config|
  config.before(:each, type: :feature) do
    allow(Routing::OrganizationsHelper::MappedHelpers).to receive(:header_organization).and_return(nil)
  end
end
