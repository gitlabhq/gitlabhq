# frozen_string_literal: true

require 'graphql'

module Graphql
  class FakeQueryType < ::GraphQL::Schema::Object
    graphql_name 'FakeQuery'

    field :hello_world, String, null: true do
      argument :message, String, required: false
    end

    field :breaking_field, String, null: true

    def hello_world(message: "world")
      "Hello #{message}!"
    end

    def breaking_field
      raise "This field is supposed to break"
    end
  end
end
