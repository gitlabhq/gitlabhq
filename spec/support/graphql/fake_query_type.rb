# frozen_string_literal: true

module Graphql
  class FakeQueryType < Types::BaseObject
    graphql_name 'FakeQuery'

    field :hello_world, String, null: true do
      argument :message, String, required: false
    end

    def hello_world(message: "world")
      "Hello #{message}!"
    end
  end
end
