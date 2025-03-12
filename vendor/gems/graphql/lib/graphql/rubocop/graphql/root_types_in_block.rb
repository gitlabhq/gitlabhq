# frozen_string_literal: true
require_relative "./base_cop"

module GraphQL
  module Rubocop
    module GraphQL
      # Identify (and auto-correct) any root types in your schema file.
      #
      # @example
      #   # bad, immediately causes Rails to load `app/graphql/types/query.rb`
      #   query Types::Query
      #
      #   # good, defers loading until the file is needed
      #   query { Types::Query }
      #
      class RootTypesInBlock < BaseCop
        MSG = "type configuration can be moved to a block to defer loading the type's file"

        def_node_matcher :root_type_config_without_block, <<-Pattern
        (
          send nil? {:query :mutation :subscription} const
        )
        Pattern

        def on_send(node)
          root_type_config_without_block(node) do
            add_offense(node) do |corrector|
              new_node_source = node.source_range.source
              new_node_source.sub!(/(query|mutation|subscription)/, '\1 {')
              new_node_source << " }"
              corrector.replace(node, new_node_source)
            end
          end
        end
      end
    end
  end
end
