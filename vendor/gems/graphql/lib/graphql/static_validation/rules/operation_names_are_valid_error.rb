# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class OperationNamesAreValidError < StaticValidation::Error
      attr_reader :operation_name

      def initialize(message, path: nil, nodes: [], name: nil)
        super(message, path: path, nodes: nodes)
        @operation_name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code
        }.tap { |h| h["operationName"] = operation_name unless operation_name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "uniquelyNamedOperations"
      end
    end
  end
end
