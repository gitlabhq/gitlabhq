# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentNamesAreUniqueError < StaticValidation::Error
      attr_reader :name

      def initialize(message, path: nil, nodes: [], name:)
        super(message, path: path, nodes: nodes)
        @name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "name" => name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "argumentNotUnique"
      end
    end
  end
end

