# frozen_string_literal: true

# Memory instrumentation can only be done if running on a valid Ruby
#
# This concept is currently tried to be upstreamed here:
# - https://github.com/ruby/ruby/pull/3978
module MemoryInstrumentationHelper
  def skip_memory_instrumentation!
    return if ::Gitlab::Memory::Instrumentation.available?

    # if we are running in CI, a test cannot be skipped
    return if ENV['CI']

    skip 'Missing a memory instrumentation patch. ' \
      'More information can be found here: https://gitlab.com/gitlab-org/gitlab/-/issues/296530.'
  end
end
