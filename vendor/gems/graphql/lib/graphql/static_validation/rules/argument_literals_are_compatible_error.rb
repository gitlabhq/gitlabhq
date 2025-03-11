# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatibleError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :argument_name
      attr_reader :argument
      attr_reader :value

      def initialize(message, path: nil, nodes: [], type:, argument_name: nil, extensions: nil, coerce_extensions: nil, argument: nil, value: nil)
        super(message, path: path, nodes: nodes)
        @type_name = type
        @argument_name = argument_name
        @extensions = extensions
        @coerce_extensions = coerce_extensions
        @argument = argument
        @value = value
      end

      # A hash representation of this Message
      def to_h
        if @coerce_extensions
          extensions = @coerce_extensions
          # This is for legacy compat -- but this key is supposed to be a GraphQL type name :confounded:
          extensions["typeName"] = "CoercionError"
        else
          extensions = {
            "code" => code,
            "typeName" => type_name
          }

          if argument_name
            extensions["argumentName"] = argument_name
          end
        end

        extensions.merge!(@extensions) unless @extensions.nil?
        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "argumentLiteralsIncompatible"
      end
    end
  end
end
