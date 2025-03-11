# frozen_string_literal: true

require "graphql/tracing/trace"
require "graphql/tracing/call_legacy_tracers"

module GraphQL
  module Tracing
    class LegacyTrace < Trace
      include CallLegacyTracers
    end
  end
end
