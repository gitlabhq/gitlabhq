# frozen_string_literal: true

# Gitlab::Auth::IpRateLimiter routes the git and container registry auth ban
# through Labkit::RateLimit when use_labkit_git_basic_auth_ban is on. Feature
# flags default on in specs, so every spec touching git auth would take the
# labkit path, including the ones that assert Allow2Ban's own semantics.
#
# The two implementations differ deliberately: the ban lands one attempt later,
# the counting window is anchored on first write rather than a wall-clock
# bucket, and register_fail! returns true on the crossing attempt rather than
# after it. So default the flag off across the suite and let the specs that
# exercise the labkit path re-enable it, which works because their before hook
# runs later.
RSpec.configure do |config|
  config.before do
    stub_feature_flags(use_labkit_git_basic_auth_ban: false)
  end
end
