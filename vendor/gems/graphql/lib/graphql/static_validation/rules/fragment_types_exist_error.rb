# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentTypesExistError < StaticValidation::Error
      attr_reader :type_name

      def initialize(message, path: nil, nodes: [], type:)
        super(message, path: path, nodes: nodes)
        @type_name = type
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "undefinedType"
      end
    end
  end
end
