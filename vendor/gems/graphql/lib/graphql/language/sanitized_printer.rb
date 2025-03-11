# frozen_string_literal: true
module GraphQL
  module Language
    # A custom printer used to print sanitized queries. It inlines provided variables
    # within the query for facilitate logging and analysis of queries.
    #
    # The printer returns `nil` if the query is invalid.
    #
    # Since the GraphQL Ruby AST for a GraphQL query doesnt contain any reference
    # on the type of fields or arguments, we have to track the current object, field
    # and input type while printing the query.
    #
    # @example Printing a scrubbed string
    #   printer = QueryPrinter.new(query)
    #   puts printer.sanitized_query_string
    #
    # @see {Query#sanitized_query_string}
    class SanitizedPrinter < GraphQL::Language::Printer

      REDACTED = "\"<REDACTED>\""

      def initialize(query, inline_variables: true)
        @query = query
        @current_type = nil
        @current_field = nil
        @current_input_type = nil
        @inline_variables = inline_variables
      end

      # @return [String, nil] A scrubbed query string, if the query was valid.
      def sanitized_query_string
        if query.valid?
          print(query.document)
        else
          nil
        end
      end

      def print_node(node, indent: "")
        case node
        when FalseClass, Float, Integer, String, TrueClass
          if @current_argument && redact_argument_value?(@current_argument, node)
            print_string(redacted_argument_value(@current_argument))
          else
            super
          end
        when Array
          old_input_type = @current_input_type
          if @current_input_type && @current_input_type.list?
            @current_input_type = @current_input_type.of_type
            @current_input_type = @current_input_type.of_type if @current_input_type.non_null?
          end

          super
          @current_input_type = old_input_type
        else
          super
        end
      end

      # Indicates whether or not to redact non-null values for the given argument. Defaults to redacting all strings
      # arguments but this can be customized by subclasses.
      def redact_argument_value?(argument, value)
        # Default to redacting any strings or custom scalars encoded as strings
        type = argument.type.unwrap
        value.is_a?(String) && type.kind.scalar? && (type.graphql_name == "String" || !type.default_scalar?)
      end

      # Returns the value to use for redacted versions of the given argument. Defaults to the
      # string "<REDACTED>".
      def redacted_argument_value(argument)
        REDACTED
      end

      def print_argument(argument)
        # We won't have type information if we're recursing into a custom scalar
        return super if @current_input_type && @current_input_type.kind.scalar?

        arg_owner = @current_input_type || @current_directive || @current_field
        old_current_argument = @current_argument
        @current_argument = arg_owner.get_argument(argument.name, @query.context)

        old_input_type = @current_input_type
        @current_input_type = @current_argument.type.non_null? ? @current_argument.type.of_type : @current_argument.type

        argument_value = if coerce_argument_value_to_list?(@current_input_type, argument.value)
          [argument.value]
        else
          argument.value
        end

        print_string("#{argument.name}: ")
        print_node(argument_value)

        @current_input_type = old_input_type
        @current_argument = old_current_argument
      end

      def coerce_argument_value_to_list?(type, value)
        type.list? &&
          !value.is_a?(Array) &&
          !value.nil? &&
          !value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      end

      def print_variable_identifier(variable_id)
        if @inline_variables
          variable_value = query.variables[variable_id.name]
          print_node(value_to_ast(variable_value, @current_input_type))
        else
          super
        end
      end

      def print_field(field, indent: "")
        @current_field = query.types.field(@current_type, field.name)
        old_type = @current_type
        @current_type = @current_field.type.unwrap
        super
        @current_type = old_type
      end

      def print_inline_fragment(inline_fragment, indent: "")
        old_type = @current_type

        if inline_fragment.type
          @current_type = query.get_type(inline_fragment.type.name)
        end

        super

        @current_type = old_type
      end

      def print_fragment_definition(fragment_def, indent: "")
        old_type = @current_type
        @current_type = query.get_type(fragment_def.type.name)

        super

        @current_type = old_type
      end

      def print_directive(directive)
        @current_directive = query.schema.directives[directive.name]

        super

        @current_directive = nil
      end

      # Print the operation definition but do not include the variable
      # definitions since we will inline them within the query
      def print_operation_definition(operation_definition, indent: "")
        old_type = @current_type
        @current_type = query.schema.public_send(operation_definition.operation_type)

        if @inline_variables
          print_string("#{indent}#{operation_definition.operation_type}")
          print_string(" #{operation_definition.name}") if operation_definition.name
          print_directives(operation_definition.directives)
          print_selections(operation_definition.selections, indent: indent)
        else
          super
        end

        @current_type = old_type
      end

      private

      def value_to_ast(value, type)
        type = type.of_type if type.non_null?

        if value.nil?
          return GraphQL::Language::Nodes::NullValue.new(name: "null")
        end

        case type.kind.name
        when "INPUT_OBJECT"
          value = if value.respond_to?(:to_unsafe_h)
            # for ActionController::Parameters
            value.to_unsafe_h
          else
            value.to_h
          end

          arguments = value.map do |key, val|
            sub_type = type.get_argument(key.to_s, @query.context).type

            GraphQL::Language::Nodes::Argument.new(
              name: key.to_s,
              value: value_to_ast(val, sub_type)
            )
          end
          GraphQL::Language::Nodes::InputObject.new(
            arguments: arguments
          )
        when "LIST"
          if value.is_a?(Array)
            value.map { |v| value_to_ast(v, type.of_type) }
          else
            [value].map { |v| value_to_ast(v, type.of_type) }
          end
        when "ENUM"
          if value.is_a?(GraphQL::Language::Nodes::Enum)
            # if it was a default value, it's already wrapped
            value
          else
            GraphQL::Language::Nodes::Enum.new(name: value)
          end
        else
          value
        end
      end

      attr_reader :query
    end
  end
end
