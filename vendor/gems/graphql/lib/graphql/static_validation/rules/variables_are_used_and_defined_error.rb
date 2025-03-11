# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariablesAreUsedAndDefinedError < StaticValidation::Error
      attr_reader :variable_name
      attr_reader :violation

      VIOLATIONS = {
        :VARIABLE_NOT_USED     => "variableNotUsed",
        :VARIABLE_NOT_DEFINED  => "variableNotDefined",
      }

      def initialize(message, path: nil, nodes: [], name:, error_type:)
        super(message, path: path, nodes: nodes)
        @variable_name = name
        raise("Unexpected error type: #{error_type}") if !VIOLATIONS.values.include?(error_type)
        @violation = error_type
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
        @violation
      end
    end
  end
end
