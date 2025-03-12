# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # Use this to implement Relay connections, or take it as inspiration
      # for Relay classes in your own app.
      #
      # You may wish to copy this code into your own base class,
      # so you can extend your own `BaseObject` instead of `GraphQL::Schema::Object`.
      #
      # @example Implementation a connection and edge
      #   class BaseObject < GraphQL::Schema::Object; end
      #
      #   # Given some object in your app ...
      #   class Types::Post < BaseObject
      #   end
      #
      #   # Make a couple of base classes:
      #   class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge; end
      #   class Types::BaseConnection < GraphQL::Types::Relay::BaseConnection; end
      #
      #   # Then extend them for the object in your app
      #   class Types::PostEdge < Types::BaseEdge
      #     node_type Types::Post
      #   end
      #
      #   class Types::PostConnection < Types::BaseConnection
      #     edge_type Types::PostEdge,
      #               edges_nullable: true,
      #               edge_nullable: true,
      #               node_nullable: true,
      #               nodes_field: true
      #
      #     # Alternatively, you can call the class methods followed by your edge type
      #     # edges_nullable true
      #     # edge_nullable true
      #     # node_nullable true
      #     # has_nodes_field true
      #     # edge_type Types::PostEdge
      #   end
      #
      # @see Relay::BaseEdge for edge types
      class BaseConnection < Schema::Object
        include ConnectionBehaviors
      end
    end
  end
end
