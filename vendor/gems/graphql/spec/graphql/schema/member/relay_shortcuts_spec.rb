# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::RelayShortcuts do
  describe ".connection_type_class, .edge_type_class" do
    class CustomBaseConnectionType < GraphQL::Types::Relay::BaseConnection
    end

    class CustomEdgeType < GraphQL::Types::Relay::BaseEdge
    end

    class ConnectionTypeBaseObject < GraphQL::Schema::Object
      connection_type_class CustomBaseConnectionType
      edge_type_class CustomEdgeType
    end

    class ImplementationTypeObject < ConnectionTypeBaseObject
      implements GraphQL::Types::Relay::Node
    end

    module ConnectionTypeBaseInterface
      include GraphQL::Schema::Interface
      connection_type_class CustomBaseConnectionType
      edge_type_class CustomEdgeType
    end

    module NodeImplementingInterface
      include ConnectionTypeBaseInterface
      implements GraphQL::Types::Relay::Node
    end

    it "uses the custom class, even when Node is implemented" do
      assert_equal CustomBaseConnectionType, ConnectionTypeBaseObject.connection_type_class
      assert_equal GraphQL::Types::Relay::BaseConnection, GraphQL::Types::Relay::Node.connection_type_class
      assert_equal CustomBaseConnectionType, ImplementationTypeObject.connection_type_class
      assert_equal CustomBaseConnectionType, ConnectionTypeBaseInterface.connection_type_class
      assert_equal CustomBaseConnectionType, NodeImplementingInterface.connection_type_class

      assert_equal CustomEdgeType, ConnectionTypeBaseObject.edge_type_class
      assert_equal GraphQL::Types::Relay::BaseEdge, GraphQL::Types::Relay::Node.edge_type_class
      assert_equal CustomEdgeType, ImplementationTypeObject.edge_type_class
      assert_equal CustomEdgeType, ConnectionTypeBaseInterface.edge_type_class
      assert_equal CustomEdgeType, NodeImplementingInterface.edge_type_class

    end
  end
end
