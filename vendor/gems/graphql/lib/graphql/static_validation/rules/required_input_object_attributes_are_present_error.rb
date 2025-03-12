# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class RequiredInputObjectAttributesArePresentError < StaticValidation::Error
      attr_reader :argument_type
      attr_reader :argument_name
      attr_reader :input_object_type

      def initialize(message, path:, nodes:, argument_type:, argument_name:, input_object_type:)
        super(message, path: path, nodes: nodes)
        @argument_type = argument_type
        @argument_name = argument_name
        @input_object_type = input_object_type
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "argumentName" => argument_name,
          "argumentType" => argument_type,
          "inputObjectType" => input_object_type,
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "missingRequiredInputObjectAttribute"
      end
    end
  end
end
