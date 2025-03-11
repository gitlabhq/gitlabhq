# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      # This can be used for Relay's `Node` interface,
      # or you can take it as inspiration for your own implementation
      # of the `Node` interface.
      module Node
        include GraphQL::Schema::Interface
        include Types::Relay::NodeBehaviors
      end
    end
  end
end
