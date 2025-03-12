# frozen_string_literal: true
require "spec_helper"
require_relative "./backend_assertions"

if testing_redis?
  describe GraphQL::Tracing::DetailedTrace::RedisBackend do
    include GraphQLTracingDetailedTraceBackendAssertions
    def new_backend(**kwargs)
      GraphQL::Tracing::DetailedTrace::RedisBackend.new(redis: Redis.new, **kwargs)
    end
  end
end
