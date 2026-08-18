# frozen_string_literal: true

module Tooling
  module Graphql
    module Docs
      module Schema
        # Abstract class for all GraphQL schema items.
        class Item
          attr_reader :item, :name, :description

          def initialize(item)
            @item = item
            @name = item.graphql_name
            @description = item.description
          end

          # A `{ title => url }` reference to external documentation, declared
          # with the `see:` option on a field or argument. Returns nil for
          # items that do not support it.
          def doc_reference
            item.try(:doc_reference)
          end

          def inspect
            "<#{self.class} #{name}>"
          end
        end
      end
    end
  end
end
