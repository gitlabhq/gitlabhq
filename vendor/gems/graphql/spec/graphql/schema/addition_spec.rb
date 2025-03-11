# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Addition do
  it "handles duplicate types with cycles" do
    duplicate_types_schema = Class.new(GraphQL::Schema)
    duplicate_types_schema.use_visibility_profile = false
    duplicate_types = 2.times.map {
      Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        field :thing, self
      end
    }
    duplicate_types_schema.orphan_types(duplicate_types)
    assert_equal 2, duplicate_types_schema.send(:own_types)["Thing"].size
  end
end
