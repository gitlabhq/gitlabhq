# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

describe GraphQL::Tracing::DetailedTrace::MemoryBackend do
  include GraphQLTracingDetailedTraceBackendAssertions
  def new_backend(**kwargs)
    GraphQL::Tracing::DetailedTrace::MemoryBackend.new(**kwargs)
  end
end
