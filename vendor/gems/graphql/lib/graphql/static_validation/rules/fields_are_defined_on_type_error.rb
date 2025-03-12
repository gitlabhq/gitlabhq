# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FieldsAreDefinedOnTypeError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :field_name

      def initialize(message, path: nil, nodes: [], type:, field:)
        super(message, path: path, nodes: nodes)
        @type_name = type
        @field_name = field
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name,
          "fieldName" => field_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "undefinedField"
      end
    end
  end
end
