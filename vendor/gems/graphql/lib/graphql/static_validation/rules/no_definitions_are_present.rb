# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module NoDefinitionsArePresent
      include GraphQL::StaticValidation::Error::ErrorHelper

      def initialize(*)
        super
        @schema_definition_nodes = []
      end

      def on_invalid_node(node, parent)
        @schema_definition_nodes << node
        nil
      end

      alias :on_directive_definition :on_invalid_node
      alias :on_schema_definition :on_invalid_node
      alias :on_scalar_type_definition :on_invalid_node
      alias :on_object_type_definition :on_invalid_node
      alias :on_input_object_type_definition :on_invalid_node
      alias :on_interface_type_definition :on_invalid_node
      alias :on_union_type_definition :on_invalid_node
      alias :on_enum_type_definition :on_invalid_node
      alias :on_schema_extension :on_invalid_node
      alias :on_scalar_type_extension :on_invalid_node
      alias :on_object_type_extension :on_invalid_node
      alias :on_input_object_type_extension :on_invalid_node
      alias :on_interface_type_extension :on_invalid_node
      alias :on_union_type_extension :on_invalid_node
      alias :on_enum_type_extension :on_invalid_node

      def on_document(node, parent)
        super
        if !@schema_definition_nodes.empty?
          add_error(GraphQL::StaticValidation::NoDefinitionsArePresentError.new(%|Query cannot contain schema definitions|, nodes: @schema_definition_nodes))
        end
      end
    end
  end
end
