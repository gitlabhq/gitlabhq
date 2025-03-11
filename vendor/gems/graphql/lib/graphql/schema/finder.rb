# frozen_string_literal: true

module GraphQL
  class Schema
    # Find schema members using string paths
    #
    # @example Finding object types
    #   MySchema.find("SomeObjectType")
    #
    # @example Finding fields
    #   MySchema.find("SomeObjectType.myField")
    #
    # @example Finding arguments
    #   MySchema.find("SomeObjectType.myField.anArgument")
    #
    # @example Finding directives
    #   MySchema.find("@include")
    #
    class Finder
      class MemberNotFoundError < ArgumentError; end

      def initialize(schema)
        @schema = schema
      end

      def find(path)
        path = path.split(".")
        type_or_directive = path.shift

        if type_or_directive.start_with?("@")
          directive = schema.directives[type_or_directive[1..-1]]

          if directive.nil?
            raise MemberNotFoundError, "Could not find directive `#{type_or_directive}` in schema."
          end

          return directive if path.empty?

          find_in_directive(directive, path: path)
        else
          type = schema.get_type(type_or_directive) # rubocop:disable Development/ContextIsPassedCop -- build-time

          if type.nil?
            raise MemberNotFoundError, "Could not find type `#{type_or_directive}` in schema."
          end

          return type if path.empty?

          find_in_type(type, path: path)
        end
      end

      private

      attr_reader :schema

      def find_in_directive(directive, path:)
        argument_name = path.shift
        argument = directive.get_argument(argument_name) # rubocop:disable Development/ContextIsPassedCop -- build-time

        if argument.nil?
          raise MemberNotFoundError, "Could not find argument `#{argument_name}` on directive #{directive}."
        end

        argument
      end

      def find_in_type(type, path:)
        case type.kind.name
        when "OBJECT"
          find_in_fields_type(type, kind: "object", path: path)
        when "INTERFACE"
          find_in_fields_type(type, kind: "interface", path: path)
        when "INPUT_OBJECT"
          find_in_input_object(type, path: path)
        when "UNION"
          # Error out if path that was provided is too long
          # i.e UnionType.PossibleType.aField
          # Use PossibleType.aField instead.
          if invalid = path.first
            raise MemberNotFoundError, "Cannot select union possible type `#{invalid}`. Select the type directly instead."
          end
        when "ENUM"
          find_in_enum_type(type, path: path)
        else
          raise "Unexpected find_in_type: #{type.inspect} (#{path})"
        end
      end

      def find_in_fields_type(type, kind:, path:)
        field_name = path.shift
        field = schema.get_field(type, field_name)

        if field.nil?
          raise MemberNotFoundError, "Could not find field `#{field_name}` on #{kind} type `#{type.graphql_name}`."
        end

        return field if path.empty?

        find_in_field(field, path: path)
      end

      def find_in_field(field, path:)
        argument_name = path.shift
        argument = field.get_argument(argument_name) # rubocop:disable Development/ContextIsPassedCop -- build-time

        if argument.nil?
          raise MemberNotFoundError, "Could not find argument `#{argument_name}` on field `#{field.name}`."
        end

        # Error out if path that was provided is too long
        # i.e Type.field.argument.somethingBad
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on a field."
        end

        argument
      end

      def find_in_input_object(input_object, path:)
        field_name = path.shift
        input_field = input_object.get_argument(field_name) # rubocop:disable Development/ContextIsPassedCop -- build-time

        if input_field.nil?
          raise MemberNotFoundError, "Could not find input field `#{field_name}` on input object type `#{input_object.graphql_name}`."
        end

        # Error out if path that was provided is too long
        # i.e InputType.inputField.bad
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on an input field."
        end

        input_field
      end

      def find_in_enum_type(enum_type, path:)
        value_name = path.shift
        enum_value = enum_type.enum_values.find { |v| v.graphql_name == value_name } # rubocop:disable Development/ContextIsPassedCop -- build-time, not runtime

        if enum_value.nil?
          raise MemberNotFoundError, "Could not find enum value `#{value_name}` on enum type `#{enum_type.graphql_name}`."
        end

        # Error out if path that was provided is too long
        # i.e Enum.VALUE.wat
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on an enum value."
        end

        enum_value
      end
    end
  end
end
