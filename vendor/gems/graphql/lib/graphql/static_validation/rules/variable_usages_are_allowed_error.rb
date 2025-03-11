# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariableUsagesAreAllowedError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :variable_name
      attr_reader :argument_name
      attr_reader :error_message

      def initialize(message, path: nil, nodes: [], type:, name:, argument:, error:)
        super(message, path: path, nodes: nodes)
        @type_name = type
        @variable_name = name
        @argument_name = argument
        @error_message = error
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name,
          "typeName" => type_name,
          "argumentName" => argument_name,
          "errorMessage" => error_message
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "variableMismatch"
      end
    end
  end
end
