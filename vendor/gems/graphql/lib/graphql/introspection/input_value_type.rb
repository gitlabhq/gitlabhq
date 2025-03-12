# frozen_string_literal: true
module GraphQL
  module Introspection
    class InputValueType < Introspection::BaseObject
      graphql_name "__InputValue"
      description "Arguments provided to Fields or Directives and the input fields of an "\
                  "InputObject are represented as Input Values which describe their type and "\
                  "optionally a default value."
      field :name, String, null: false
      field :description, String
      field :type, GraphQL::Schema::LateBoundType.new("__Type"), null: false
      field :default_value, String, "A GraphQL-formatted string representing the default value for this input value."
      field :is_deprecated, Boolean, null: false
      field :deprecation_reason, String

      def is_deprecated
        !!@object.deprecation_reason
      end

      def default_value
        if @object.default_value?
          value = @object.default_value
          if value.nil?
            'null'
          else
            if (@object.type.kind.list? || (@object.type.kind.non_null? && @object.type.of_type.kind.list?)) && !value.respond_to?(:map)
              # This is a bit odd -- we expect the default value to be an application-style value, so we use coerce result below.
              # But coerce_result doesn't wrap single-item lists, which are valid inputs to list types.
              # So, apply that wrapper here if needed.
              value = [value]
            end
            coerced_default_value = @object.type.coerce_result(value, @context)
            serialize_default_value(coerced_default_value, @object.type)
          end
        else
          nil
        end
      end


      private

      # Recursively serialize, taking care not to add quotes to enum values
      def serialize_default_value(value, type)
        if value.nil?
          'null'
        elsif type.kind.list?
          inner_type = type.of_type
          "[" + value.map { |v| serialize_default_value(v, inner_type) }.join(", ") + "]"
        elsif type.kind.non_null?
          serialize_default_value(value, type.of_type)
        elsif type.kind.enum?
          value
        elsif type.kind.input_object?
          "{" +
            value.map do |k, v|
              arg_defn = type.get_argument(k, context)
              "#{k}: #{serialize_default_value(v, arg_defn.type)}"
            end.join(", ") +
            "}"
        else
          GraphQL::Language.serialize(value)
        end
      end
    end
  end
end
