# frozen_string_literal: true

# Memory instrumentation can only be done if running on a valid Ruby
#
# This concept is currently tried to be upstreamed here:
# - https://github.com/ruby/ruby/pull/3978
module MemoryInstrumentationHelper
  def verify_memory_instrumentation_available!
    return if ::Gitlab::Memory::Instrumentation.available?

    raise 'Ruby is missing a required patch that enables memory instrumentation. ' \
      'More information can be found here: https://gitlab.com/gitlab-org/gitlab/-/issues/296530.'
  end
end
