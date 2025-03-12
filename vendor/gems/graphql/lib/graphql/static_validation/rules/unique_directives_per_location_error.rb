# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class UniqueDirectivesPerLocationError < StaticValidation::Error
      attr_reader :directive_name

      def initialize(message, path: nil, nodes: [], directive:)
        super(message, path: path, nodes: nodes)
        @directive_name = directive
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "directiveName" => directive_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "directiveNotUniqueForLocation"
      end
    end
  end
end
