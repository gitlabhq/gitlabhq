# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariableDefaultValuesAreCorrectlyTypedError < StaticValidation::Error
      attr_reader :variable_name
      attr_reader :type_name
      attr_reader :violation

      VIOLATIONS = {
        :INVALID_TYPE         => "defaultValueInvalidType",
        :INVALID_ON_NON_NULL  => "defaultValueInvalidOnNonNullVariable",
      }

      def initialize(message, path: nil, nodes: [], name:, type: nil, error_type:)
        super(message, path: path, nodes: nodes)
        @variable_name = name
        @type_name = type
        raise("Unexpected error type: #{error_type}") if !VIOLATIONS.values.include?(error_type)
        @violation = error_type
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name
        }.tap { |h| h["typeName"] = type_name unless type_name.nil? }

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
