# frozen_string_literal: true

class NotInstalledSchema < GraphQL::Schema
  class Query < GraphQL::Schema::Object
    field :str, String, fallback_value: "hello"
  end

  query(Query)
end
