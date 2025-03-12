# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::HasNodeField do
  it "populates .owner when it's included" do
    query = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      include GraphQL::Types::Relay::HasNodeField
      include GraphQL::Types::Relay::HasNodesField
    end

    node_field = query.fields["node"]
    assert_equal query, node_field.owner
    assert_equal query, node_field.owner_type

    nodes_field = query.fields["nodes"]
    assert_equal query, nodes_field.owner
    assert_equal query, nodes_field.owner_type
  end
end
