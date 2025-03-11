# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariableNamesAreUniqueError < StaticValidation::Error
      attr_reader :variable_name

      def initialize(message, path: nil, nodes: [], name:)
        super(message, path: path, nodes: nodes)
        @variable_name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "variableNotUnique"
      end
    end
  end
end
