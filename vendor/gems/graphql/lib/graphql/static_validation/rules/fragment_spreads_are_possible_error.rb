# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentSpreadsArePossibleError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :fragment_name
      attr_reader :parent_name

      def initialize(message, path: nil, nodes: [], type:, fragment_name:, parent:)
        super(message, path: path, nodes: nodes)
        @type_name = type
        @fragment_name = fragment_name
        @parent_name = parent
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name,
          "fragmentName" => fragment_name,
          "parentName" => parent_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "cannotSpreadFragment"
      end
    end
  end
end
