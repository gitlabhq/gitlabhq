# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FieldsHaveAppropriateSelectionsError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :node_name

      def initialize(message, path: nil, nodes: [], node_name:, type: nil)
        super(message, path: path, nodes: nodes)
        @node_name = node_name
        @type_name = type
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "nodeName" => node_name
        }.tap { |h| h["typeName"] = type_name unless type_name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "selectionMismatch"
      end
    end
  end
end
