# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DirectivesAreInValidLocationsError < StaticValidation::Error
      attr_reader :target_name
      attr_reader :name

      def initialize(message, path: nil, nodes: [], target:, name: nil)
        super(message, path: path, nodes: nodes)
        @target_name = target
        @name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "targetName" => target_name
        }.tap { |h| h["name"] = name unless name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "directiveCannotBeApplied"
      end
    end
  end
end
