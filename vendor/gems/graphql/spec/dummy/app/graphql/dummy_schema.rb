# frozen_string_literal: true

class DummySchema < GraphQL::Schema
  class Query < GraphQL::Schema::Object
    field :str, String, fallback_value: "hello"
  end

  query(Query)
  use GraphQL::Tracing::DetailedTrace, memory: true

  def self.detailed_trace?(query)
    query.context[:profile]
  end
end
