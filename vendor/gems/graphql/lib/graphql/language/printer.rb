# frozen_string_literal: true
module GraphQL
  module Language
    class Printer
      OMISSION = "... (truncated)"

      class TruncatableBuffer
        class TruncateSizeReached < StandardError; end

        DEFAULT_INIT_CAPACITY = 500

        def initialize(truncate_size: nil)
          @out = String.new(capacity: truncate_size || DEFAULT_INIT_CAPACITY)
          @truncate_size = truncate_size
        end

        def append(other)
          if @truncate_size && (@out.size + other.size) > @truncate_size
            @out << other.slice(0, @truncate_size - @out.size)
            raise(TruncateSizeReached, "Truncate size reached")
          else
            @out << other
          end
        end

        def to_string
          @out
        end
      end

      # Turn an arbitrary AST node back into a string.
      #
      # @example Turning a document into a query string
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Printer.new.print(document)
      #    # => "{ ... }"
      #
      #
      # @example Building a custom printer
      #
      #  class MyPrinter < GraphQL::Language::Printer
      #    def print_argument(arg)
      #      print_string("#{arg.name}: <HIDDEN>")
      #    end
      #  end
      #
      #  MyPrinter.new.print(document)
      #  # => "mutation { pay(creditCard: <HIDDEN>) { success } }"
      #
      # @param node [Nodes::AbstractNode]
      # @param indent [String] Whitespace to add to the printed node
      # @param truncate_size [Integer, nil] The size to truncate to.
      # @return [String] Valid GraphQL for `node`
      def print(node, indent: "", truncate_size: nil)
        truncate_size = truncate_size ? [truncate_size - OMISSION.size, 0].max : nil
        @out = TruncatableBuffer.new(truncate_size: truncate_size)
        print_node(node, indent: indent)
        @out.to_string
      rescue TruncatableBuffer::TruncateSizeReached
        @out.to_string << OMISSION
      end

      protected

      def print_string(str)
        @out.append(str)
      end

      def print_document(document)
        document.definitions.each_with_index do |d, i|
          print_node(d)
          print_string("\n\n") if i < document.definitions.size - 1
        end
      end

      def print_argument(argument)
        print_string(argument.name)
        print_string(": ")
        print_node(argument.value)
      end

      def print_input_object(input_object)
        print_string("{")
        input_object.arguments.each_with_index do |a, i|
          print_argument(a)
          print_string(", ") if i < input_object.arguments.size - 1
        end
        print_string("}")
      end

      def print_directive(directive)
        print_string("@")
        print_string(directive.name)

        if !directive.arguments.empty?
          print_string("(")
          directive.arguments.each_with_index do |a, i|
            print_argument(a)
            print_string(", ") if i < directive.arguments.size - 1
          end
          print_string(")")
        end
      end

      def print_enum(enum)
        print_string(enum.name)
      end

      def print_null_value
        print_string("null")
      end

      def print_field(field, indent: "")
        print_string(indent)
        if field.alias
          print_string(field.alias)
          print_string(": ")
        end
        print_string(field.name)
        if !field.arguments.empty?
          print_string("(")
          field.arguments.each_with_index do |a, i|
            print_argument(a)
            print_string(", ") if i < field.arguments.size - 1
          end
          print_string(")")
        end
        print_directives(field.directives)
        print_selections(field.selections, indent: indent)
      end

      def print_fragment_definition(fragment_def, indent: "")
        print_string(indent)
        print_string("fragment")
        if fragment_def.name
          print_string(" ")
          print_string(fragment_def.name)
        end

        if fragment_def.type
          print_string(" on ")
          print_node(fragment_def.type)
        end
        print_directives(fragment_def.directives)
        print_selections(fragment_def.selections, indent: indent)
      end

      def print_fragment_spread(fragment_spread, indent: "")
        print_string(indent)
        print_string("...")
        print_string(fragment_spread.name)
        print_directives(fragment_spread.directives)
      end

      def print_inline_fragment(inline_fragment, indent: "")
        print_string(indent)
        print_string("...")
        if inline_fragment.type
          print_string(" on ")
          print_node(inline_fragment.type)
        end
        print_directives(inline_fragment.directives)
        print_selections(inline_fragment.selections, indent: indent)
      end

      def print_list_type(list_type)
        print_string("[")
        print_node(list_type.of_type)
        print_string("]")
      end

      def print_non_null_type(non_null_type)
        print_node(non_null_type.of_type)
        print_string("!")
      end

      def print_operation_definition(operation_definition, indent: "")
        print_string(indent)
        print_string(operation_definition.operation_type)
        if operation_definition.name
          print_string(" ")
          print_string(operation_definition.name)
        end

        if !operation_definition.variables.empty?
          print_string("(")
          operation_definition.variables.each_with_index do |v, i|
            print_variable_definition(v)
            print_string(", ") if i < operation_definition.variables.size - 1
          end
          print_string(")")
        end

        print_directives(operation_definition.directives)
        print_selections(operation_definition.selections, indent: indent)
      end

      def print_type_name(type_name)
        print_string(type_name.name)
      end

      def print_variable_definition(variable_definition)
        print_string("$")
        print_string(variable_definition.name)
        print_string(": ")
        print_node(variable_definition.type)
        unless variable_definition.default_value.nil?
          print_string(" = ")
          print_node(variable_definition.default_value)
        end
        variable_definition.directives.each do |dir|
          print_string(" ")
          print_directive(dir)
        end
      end

      def print_variable_identifier(variable_identifier)
        print_string("$")
        print_string(variable_identifier.name)
      end

      def print_schema_definition(schema, extension: false)
        has_conventional_names = (schema.query.nil? || schema.query == 'Query') &&
          (schema.mutation.nil? || schema.mutation == 'Mutation') &&
          (schema.subscription.nil? || schema.subscription == 'Subscription')

        if has_conventional_names && schema.directives.empty?
          return
        end

        extension ? print_string("extend schema") : print_string("schema")

        if !schema.directives.empty?
          schema.directives.each do |dir|
            print_string("\n  ")
            print_node(dir)
          end

          if !has_conventional_names
            print_string("\n")
          end
        end

        if !has_conventional_names
          if schema.directives.empty?
            print_string(" ")
          end
          print_string("{\n")
          print_string("  query: #{schema.query}\n") if schema.query
          print_string("  mutation: #{schema.mutation}\n") if schema.mutation
          print_string("  subscription: #{schema.subscription}\n") if schema.subscription
          print_string("}")
        end
      end


      def print_scalar_type_definition(scalar_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(scalar_type)
        print_string("scalar ")
        print_string(scalar_type.name)
        print_directives(scalar_type.directives)
      end

      def print_object_type_definition(object_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(object_type)
        print_string("type ")
        print_string(object_type.name)
        print_implements(object_type) unless object_type.interfaces.empty?
        print_directives(object_type.directives)
        print_field_definitions(object_type.fields)
      end

      def print_implements(type)
        print_string(" implements ")
        i = 0
        type.interfaces.each do |int|
          if i > 0
            print_string(" & ")
          end
          print_string(int.name)
          i += 1
        end
      end

      def print_input_value_definition(input_value)
        print_string(input_value.name)
        print_string(": ")
        print_node(input_value.type)
        unless input_value.default_value.nil?
          print_string(" = ")
          print_node(input_value.default_value)
        end
        print_directives(input_value.directives)
      end

      def print_arguments(arguments, indent: "")
        if arguments.all? { |arg| !arg.description && !arg.comment }
          print_string("(")
          arguments.each_with_index do |arg, i|
            print_input_value_definition(arg)
            print_string(", ") if i < arguments.size - 1
          end
          print_string(")")
          return
        end

        print_string("(\n")
        arguments.each_with_index do |arg, i|
          print_comment(arg, indent: "  " + indent, first_in_block: i == 0)
          print_description(arg, indent: "  " + indent, first_in_block: i == 0)
          print_string("  ")
          print_string(indent)
          print_input_value_definition(arg)
          print_string("\n") if i < arguments.size - 1
        end
        print_string("\n")
        print_string(indent)
        print_string(")")
      end

      def print_field_definition(field)
        print_string(field.name)
        unless field.arguments.empty?
          print_arguments(field.arguments, indent: "  ")
        end
        print_string(": ")
        print_node(field.type)
        print_directives(field.directives)
      end

      def print_interface_type_definition(interface_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(interface_type)
        print_string("interface ")
        print_string(interface_type.name)
        print_implements(interface_type) if !interface_type.interfaces.empty?
        print_directives(interface_type.directives)
        print_field_definitions(interface_type.fields)
      end

      def print_union_type_definition(union_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(union_type)
        print_string("union ")
        print_string(union_type.name)
        print_directives(union_type.directives)
        if !union_type.types.empty?
          print_string(" = ")
          i = 0
          union_type.types.each do |t|
            if i > 0
              print_string(" | ")
            end
            print_string(t.name)
            i += 1
          end
        end
      end

      def print_enum_type_definition(enum_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(enum_type)
        print_string("enum ")
        print_string(enum_type.name)
        print_directives(enum_type.directives)
        if !enum_type.values.empty?
          print_string(" {\n")
          enum_type.values.each.with_index do |value, i|
            print_description(value, indent: "  ", first_in_block: i == 0)
            print_comment(value, indent: "  ", first_in_block: i == 0)
            print_enum_value_definition(value)
          end
          print_string("}")
        end
      end

      def print_enum_value_definition(enum_value)
        print_string("  ")
        print_string(enum_value.name)
        print_directives(enum_value.directives)
        print_string("\n")
      end

      def print_input_object_type_definition(input_object_type, extension: false)
        extension ? print_string("extend ") : print_description_and_comment(input_object_type)
        print_string("input ")
        print_string(input_object_type.name)
        print_directives(input_object_type.directives)
        if !input_object_type.fields.empty?
          print_string(" {\n")
          input_object_type.fields.each.with_index do |field, i|
            print_description(field, indent: "  ", first_in_block: i == 0)
            print_comment(field, indent: "  ", first_in_block: i == 0)
            print_string("  ")
            print_input_value_definition(field)
            print_string("\n")
          end
          print_string("}")
        end
      end

      def print_directive_definition(directive)
        print_description(directive)
        print_string("directive @")
        print_string(directive.name)

        if !directive.arguments.empty?
          print_arguments(directive.arguments)
        end

        if directive.repeatable
          print_string(" repeatable")
        end

        print_string(" on ")
        i = 0
        directive.locations.each do |loc|
          if i > 0
            print_string(" | ")
          end
          print_string(loc.name)
          i += 1
        end
      end

      def print_description(node, indent: "", first_in_block: true)
        return unless node.description

        print_string("\n") if indent != "" && !first_in_block
        print_string(GraphQL::Language::BlockString.print(node.description, indent: indent))
      end

      def print_comment(node, indent: "", first_in_block: true)
        return unless node.comment

        print_string("\n") if indent != "" && !first_in_block
        print_string(GraphQL::Language::Comment.print(node.comment, indent: indent))
      end

      def print_description_and_comment(node)
        print_description(node)
        print_comment(node)
      end

      def print_field_definitions(fields)
        return if fields.empty?

        print_string(" {\n")
        i = 0
        fields.each do |field|
          print_description(field, indent: "  ", first_in_block: i == 0)
          print_comment(field, indent: "  ", first_in_block: i == 0)
          print_string("  ")
          print_field_definition(field)
          print_string("\n")
          i += 1
        end
        print_string("}")
      end

      def print_directives(directives)
        return if directives.empty?

        directives.each do |d|
          print_string(" ")
          print_directive(d)
        end
      end

      def print_selections(selections, indent: "")
        return if selections.empty?

        print_string(" {\n")
        selections.each do |selection|
          print_node(selection, indent: indent + "  ")
          print_string("\n")
        end
        print_string(indent)
        print_string("}")
      end

      def print_node(node, indent: "")
        case node
        when Nodes::Document
          print_document(node)
        when Nodes::Argument
          print_argument(node)
        when Nodes::Directive
          print_directive(node)
        when Nodes::Enum
          print_enum(node)
        when Nodes::NullValue
          print_null_value
        when Nodes::Field
          print_field(node, indent: indent)
        when Nodes::FragmentDefinition
          print_fragment_definition(node, indent: indent)
        when Nodes::FragmentSpread
          print_fragment_spread(node, indent: indent)
        when Nodes::InlineFragment
          print_inline_fragment(node, indent: indent)
        when Nodes::InputObject
          print_input_object(node)
        when Nodes::ListType
          print_list_type(node)
        when Nodes::NonNullType
          print_non_null_type(node)
        when Nodes::OperationDefinition
          print_operation_definition(node, indent: indent)
        when Nodes::TypeName
          print_type_name(node)
        when Nodes::VariableDefinition
          print_variable_definition(node)
        when Nodes::VariableIdentifier
          print_variable_identifier(node)
        when Nodes::SchemaDefinition
          print_schema_definition(node)
        when Nodes::SchemaExtension
          print_schema_definition(node, extension: true)
        when Nodes::ScalarTypeDefinition
          print_scalar_type_definition(node)
        when Nodes::ScalarTypeExtension
          print_scalar_type_definition(node, extension: true)
        when Nodes::ObjectTypeDefinition
          print_object_type_definition(node)
        when Nodes::ObjectTypeExtension
          print_object_type_definition(node, extension: true)
        when Nodes::InputValueDefinition
          print_input_value_definition(node)
        when Nodes::FieldDefinition
          print_field_definition(node)
        when Nodes::InterfaceTypeDefinition
          print_interface_type_definition(node)
        when Nodes::InterfaceTypeExtension
          print_interface_type_definition(node, extension: true)
        when Nodes::UnionTypeDefinition
          print_union_type_definition(node)
        when Nodes::UnionTypeExtension
          print_union_type_definition(node, extension: true)
        when Nodes::EnumTypeDefinition
          print_enum_type_definition(node)
        when Nodes::EnumTypeExtension
          print_enum_type_definition(node, extension: true)
        when Nodes::EnumValueDefinition
          print_enum_value_definition(node)
        when Nodes::InputObjectTypeDefinition
          print_input_object_type_definition(node)
        when Nodes::InputObjectTypeExtension
          print_input_object_type_definition(node, extension: true)
        when Nodes::DirectiveDefinition
          print_directive_definition(node)
        when FalseClass, Float, Integer, NilClass, String, TrueClass, Symbol
          print_string(GraphQL::Language.serialize(node))
        when Array
          print_string("[")
          node.each_with_index do |v, i|
            print_node(v)
            print_string(", ") if i < node.length - 1
          end
          print_string("]")
        when Hash
          print_string("{")
          node.each_with_index do |(k, v), i|
            print_string(k)
            print_string(": ")
            print_node(v)
            print_string(", ") if i < node.length - 1
          end
          print_string("}")
        else
          print_string(GraphQL::Language.serialize(node.to_s))
        end
      end
    end
  end
end
