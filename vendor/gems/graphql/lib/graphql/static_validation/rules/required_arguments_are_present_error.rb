# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class RequiredArgumentsArePresentError < StaticValidation::Error
      attr_reader :class_name
      attr_reader :name
      attr_reader :arguments

      def initialize(message, path: nil, nodes: [], class_name:, name:, arguments:)
        super(message, path: path, nodes: nodes)
        @class_name = class_name
        @name = name
        @arguments = arguments
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "className" => class_name,
          "name" => name,
          "arguments" => arguments
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "missingRequiredArguments"
      end
    end
  end
end
