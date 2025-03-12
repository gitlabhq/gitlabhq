# frozen_string_literal: true
module GraphQL
  module Analysis
    class FieldUsage < Analyzer
      def initialize(query)
        super
        @used_fields = Set.new
        @used_deprecated_fields = Set.new
        @used_deprecated_arguments = Set.new
        @used_deprecated_enum_values = Set.new
      end

      def on_leave_field(node, parent, visitor)
        field_defn = visitor.field_definition
        field = "#{visitor.parent_type_definition.graphql_name}.#{field_defn.graphql_name}"
        @used_fields << field
        @used_deprecated_fields << field if field_defn.deprecation_reason
        arguments = visitor.query.arguments_for(node, field_defn)
        # If there was an error when preparing this argument object,
        # then this might be an error or something:
        if arguments.respond_to?(:argument_values)
          extract_deprecated_arguments(arguments.argument_values)
        end
      end

      def result
        {
          used_fields: @used_fields.to_a,
          used_deprecated_fields: @used_deprecated_fields.to_a,
          used_deprecated_arguments: @used_deprecated_arguments.to_a,
          used_deprecated_enum_values: @used_deprecated_enum_values.to_a,
        }
      end

      private

      def extract_deprecated_arguments(argument_values)
        argument_values.each_pair do |_argument_name, argument|
          if argument.definition.deprecation_reason
            @used_deprecated_arguments << argument.definition.path
          end

          arg_val = argument.value

          next if arg_val.nil?

          argument_type = argument.definition.type
          if argument_type.non_null?
            argument_type = argument_type.of_type
          end

          if argument_type.kind.input_object?
            extract_deprecated_arguments(argument.original_value.arguments.argument_values) # rubocop:disable Development/ContextIsPassedCop -- runtime args instance
          elsif argument_type.kind.enum?
            extract_deprecated_enum_value(argument_type, arg_val)
          elsif argument_type.list?
            inner_type = argument_type.unwrap
            case inner_type.kind
            when TypeKinds::INPUT_OBJECT
              argument.original_value.each do |value|
                extract_deprecated_arguments(value.arguments.argument_values) # rubocop:disable Development/ContextIsPassedCop -- runtime args instance
              end
            when TypeKinds::ENUM
              arg_val.each do |value|
                extract_deprecated_enum_value(inner_type, value)
              end
            else
              # Not a kind of input that we track
            end
          end
        end
      end

      def extract_deprecated_enum_value(enum_type, value)
        enum_value = @query.types.enum_values(enum_type).find { |ev| ev.value == value }
        if enum_value&.deprecation_reason
          @used_deprecated_enum_values << enum_value.path
        end
      end
    end
  end
end
