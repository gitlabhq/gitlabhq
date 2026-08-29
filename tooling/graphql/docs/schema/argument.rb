# frozen_string_literal: true

require_relative 'item'
require_relative 'concerns/deprecable'
require_relative 'concerns/typeable'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A single argument on a GraphQL input object or field.
        class Argument < Item
          include Deprecable
          include Typeable
        end
      end
    end
  end
end
