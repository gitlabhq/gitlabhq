# frozen_string_literal: true
module GraphQL
  module Types
    module Relay
      # The return type of a connection's `pageInfo` field
      class PageInfo < GraphQL::Schema::Object
        include PageInfoBehaviors
      end
    end
  end
end
