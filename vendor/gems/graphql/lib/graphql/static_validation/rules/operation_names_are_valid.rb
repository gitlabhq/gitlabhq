# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module OperationNamesAreValid
      def initialize(*)
        super
        @operation_names = Hash.new { |h, k| h[k] = [] }
      end

      def on_operation_definition(node, parent)
        @operation_names[node.name] << node
        super
      end

      def on_document(node, parent)
        super
        op_count = @operation_names.values.inject(0) { |m, v| m + v.size }

        @operation_names.each do |name, nodes|
          if name.nil? && op_count > 1
            add_error(GraphQL::StaticValidation::OperationNamesAreValidError.new(
              %|Operation name is required when multiple operations are present|,
              nodes: nodes
            ))
          elsif nodes.length > 1
            add_error(GraphQL::StaticValidation::OperationNamesAreValidError.new(
              %|Operation name "#{name}" must be unique|,
              nodes: nodes,
              name: name
            ))
          end
        end
      end
    end
  end
end
