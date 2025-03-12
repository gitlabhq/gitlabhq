# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FieldsWillMergeError < StaticValidation::Error
      attr_reader :field_name
      attr_reader :kind

      def initialize(kind:, field_name:)
        super(nil)

        @field_name = field_name
        @kind = kind
        @conflicts = []
      end

      def message
        "Field '#{field_name}' has #{kind == :argument ? 'an' : 'a'} #{kind} conflict: #{conflicts}?"
      end

      def path
        []
      end

      def conflicts
        @conflicts.join(' or ')
      end

      def add_conflict(node, conflict_str)
        return if nodes.include?(node)

        @nodes << node
        @conflicts << conflict_str
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "fieldName" => field_name,
          "conflicts" => conflicts
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "fieldConflict"
      end
    end
  end
end
