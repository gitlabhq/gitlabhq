# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreOnCompositeTypesError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :argument_name

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
        "fragmentOnNonCompositeType"
      end
    end
  end
end
