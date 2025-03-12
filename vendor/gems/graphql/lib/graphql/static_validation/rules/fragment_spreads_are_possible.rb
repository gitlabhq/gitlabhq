# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentSpreadsArePossible
      def initialize(*)
        super
        @spreads_to_validate = []
      end

      def on_inline_fragment(node, parent)
        fragment_parent = context.object_types[-2]
        fragment_child = context.object_types.last
        if fragment_child
          validate_fragment_in_scope(fragment_parent, fragment_child, node, context, context.path)
        end
        super
      end

      def on_fragment_spread(node, parent)
        fragment_parent = context.object_types.last
        @spreads_to_validate << FragmentSpread.new(node: node, parent_type: fragment_parent, path: context.path)
        super
      end

      def on_document(node, parent)
        super
        @spreads_to_validate.each do |frag_spread|
          frag_node = context.fragments[frag_spread.node.name]
          if frag_node
            fragment_child_name = frag_node.type.name
            fragment_child = @types.type(fragment_child_name)
            # Might be non-existent type name
            if fragment_child
              validate_fragment_in_scope(frag_spread.parent_type, fragment_child, frag_spread.node, context, frag_spread.path)
            end
          end
        end
      end

      private

      def validate_fragment_in_scope(parent_type, child_type, node, context, path)
        if !child_type.kind.fields?
          # It's not a valid fragment type, this error was handled someplace else
          return
        end
        parent_types = @types.possible_types(parent_type.unwrap)
        child_types = @types.possible_types(child_type.unwrap)

        if child_types.none? { |c| parent_types.include?(c) }
          name = node.respond_to?(:name) ? " #{node.name}" : ""
          add_error(GraphQL::StaticValidation::FragmentSpreadsArePossibleError.new(
            "Fragment#{name} on #{child_type.graphql_name} can't be spread inside #{parent_type.graphql_name}",
            nodes: node,
            path: path,
            fragment_name: name.empty? ? "unknown" : name,
            type: child_type.graphql_name,
            parent: parent_type.graphql_name
          ))
        end
      end

      class FragmentSpread
        attr_reader :node, :parent_type, :path
        def initialize(node:, parent_type:, path:)
          @node = node
          @parent_type = parent_type
          @path = path
        end
      end
    end
  end
end
