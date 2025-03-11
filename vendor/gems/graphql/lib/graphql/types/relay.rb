# frozen_string_literal: true

# behavior modules:
require "graphql/types/relay/connection_behaviors"
require "graphql/types/relay/edge_behaviors"
require "graphql/types/relay/node_behaviors"
require "graphql/types/relay/page_info_behaviors"
require "graphql/types/relay/has_node_field"
require "graphql/types/relay/has_nodes_field"

# concrete classes based on the gem defaults:
require "graphql/types/relay/page_info"
require "graphql/types/relay/base_connection"
require "graphql/types/relay/base_edge"
require "graphql/types/relay/node"

module GraphQL
  module Types
    # This module contains some types and fields that could support Relay conventions in GraphQL.
    #
    # You can use these classes out of the box if you want, but if you want to use your _own_
    # GraphQL extensions along with the features in this code, you could also
    # open up the source files and copy the relevant methods and configuration into
    # your own classes.
    #
    # For example, the provided object types extend {Types::Relay::BaseObject},
    # but you might want to:
    #
    # 1. Migrate the extensions from {Types::Relay::BaseObject} into _your app's_ base object
    # 2. Copy {Relay::BaseConnection}, {Relay::BaseEdge}, etc into _your app_, and
    #   change them to extend _your_ base object.
    #
    # Similarly, `BaseField`'s extensions could be migrated to your app
    # and `Node` could be implemented to mix in your base interface module.
    module Relay
    end
  end
end
