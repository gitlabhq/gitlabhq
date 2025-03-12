# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::BaseEdge do
  module NonNullableDummy
    class NonNullableNode < GraphQL::Schema::Object
      field :some_field, String
    end

    class NonNullableNodeEdgeType < GraphQL::Types::Relay::BaseEdge
      node_type(NonNullableNode, null: false)
    end

    class NonNullableNodeClassOverrideEdgeType < GraphQL::Types::Relay::BaseEdge
      node_nullable(false)
    end

    class NonNullableNodeEdgeConnectionType < GraphQL::Types::Relay::BaseConnection
      edge_type(NonNullableNodeEdgeType, nodes_field: false)
    end

    class Query < GraphQL::Schema::Object
      field :connection, NonNullableNodeEdgeConnectionType, null: false
    end

    class Schema < GraphQL::Schema
      query Query
    end
  end

  it "runs the introspection query and the result contains a edge field that has non-nullable node" do
    res = NonNullableDummy::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    assert res
    edge_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "NonNullableNodeEdge" }
    node_field = edge_type["fields"].find { |f| f["name"] == "node" }
    assert_equal "NON_NULL", node_field["type"]["kind"]
    assert_equal "NonNullableNode", node_field["type"]["ofType"]["name"]
  end

  it "supports class-level node_nullable config" do
    assert_equal false, NonNullableDummy::NonNullableNodeClassOverrideEdgeType.node_nullable
  end

  it "Supports extra kwargs for node field" do
    extension = Class.new(GraphQL::Schema::FieldExtension)
    connection = Class.new(GraphQL::Types::Relay::BaseEdge) do
      node_type(GraphQL::Schema::Object, field_options: { extensions: [extension] })
    end

    field = connection.fields["node"]
    assert_equal 1, field.extensions.size
    assert_instance_of extension, field.extensions.first
  end

  it "is a default relay type" do
    edge_type = NonNullableDummy::Schema.get_type("NonNullableNodeEdge")
    assert_equal true, edge_type.default_relay?
    assert_equal true, GraphQL::Types::Relay::BaseEdge.default_relay?
  end
end
