# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class OneOfInputObjectsAreValidError < StaticValidation::Error
      attr_reader :input_object_type

      def initialize(message, path:, nodes:, input_object_type:)
        super(message, path: path, nodes: nodes)
        @input_object_type = input_object_type
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "inputObjectType" => input_object_type
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "invalidOneOfInputObject"
      end
    end
  end
end
