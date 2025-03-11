# frozen_string_literal: true
module GraphQL
  class Schema
    # Used to convert your {GraphQL::Schema} to a GraphQL schema string
    #
    # @example print your schema to standard output (via helper)
    #   puts GraphQL::Schema::Printer.print_schema(MySchema)
    #
    # @example print your schema to standard output
    #   puts GraphQL::Schema::Printer.new(MySchema).print_schema
    #
    # @example print a single type to standard output
    #   class Types::Query < GraphQL::Schema::Object
    #     description "The query root of this schema"
    #
    #     field :post, Types::Post, null: true
    #   end
    #
    #   class Types::Post < GraphQL::Schema::Object
    #     description "A blog post"
    #
    #     field :id, ID, null: false
    #     field :title, String, null: false
    #     field :body, String, null: false
    #   end
    #
    #   class MySchema < GraphQL::Schema
    #     query(Types::Query)
    #   end
    #
    #   printer = GraphQL::Schema::Printer.new(MySchema)
    #   puts printer.print_type(Types::Post)
    #
    class Printer < GraphQL::Language::Printer
      attr_reader :schema, :warden

      # @param schema [GraphQL::Schema]
      # @param context [Hash]
      # @param introspection [Boolean] Should include the introspection types in the string?
      def initialize(schema, context: nil, introspection: false)
        @document_from_schema = GraphQL::Language::DocumentFromSchemaDefinition.new(
          schema,
          context: context,
          include_introspection_types: introspection,
        )

        @document = @document_from_schema.document
        @schema = schema
      end

      # Return the GraphQL schema string for the introspection type system
      def self.print_introspection_schema
        query_root = Class.new(GraphQL::Schema::Object) do
          graphql_name "Root"
          field :throwaway_field, String
          def self.visible?(ctx)
            false
          end
        end
        schema = Class.new(GraphQL::Schema) {
          use GraphQL::Schema::Visibility
          query(query_root)
          def self.visible?(member, _ctx)
            member.graphql_name != "Root"
          end
        }

        introspection_schema_ast = GraphQL::Language::DocumentFromSchemaDefinition.new(
          schema,
          include_introspection_types: true,
          include_built_in_directives: true,
        ).document

        introspection_schema_ast.to_query_string(printer: IntrospectionPrinter.new)
      end

      # Return a GraphQL schema string for the defined types in the schema
      # @param schema [GraphQL::Schema]
      # @param context [Hash]
      # @param only [<#call(member, ctx)>]
      # @param except [<#call(member, ctx)>]
      def self.print_schema(schema, **args)
        printer = new(schema, **args)
        printer.print_schema
      end

      # Return a GraphQL schema string for the defined types in the schema
      def print_schema
        print(@document) + "\n"
      end

      def print_type(type)
        node = @document_from_schema.build_type_definition_node(type)
        print(node)
      end

      class IntrospectionPrinter < GraphQL::Language::Printer
        def print_schema_definition(schema)
          print_string("schema {\n  query: Root\n}")
        end
      end
    end
  end
end
