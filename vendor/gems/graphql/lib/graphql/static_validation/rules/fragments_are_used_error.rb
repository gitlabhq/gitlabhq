# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreUsedError < StaticValidation::Error
      attr_reader :fragment_name

      def initialize(message, path: nil, nodes: [], fragment:)
        super(message, path: path, nodes: nodes)
        @fragment_name = fragment
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "fragmentName" => fragment_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "useAndDefineFragment"
      end
    end
  end
end
