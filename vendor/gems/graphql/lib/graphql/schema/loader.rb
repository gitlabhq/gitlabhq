# frozen_string_literal: true
module GraphQL
  class Schema
    # You can use the result of {GraphQL::Introspection::INTROSPECTION_QUERY}
    # to make a schema. This schema is missing some important details like
    # `resolve` functions, but it does include the full type system,
    # so you can use it to validate queries.
    #
    # @see GraphQL::Schema.from_introspection for a public API
    module Loader
      extend self

      # Create schema with the result of an introspection query.
      # @param introspection_result [Hash] A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
      # @return [Class] the schema described by `input`
      def load(introspection_result)
        schema = introspection_result.fetch("data").fetch("__schema")

        types = {}
        type_resolver = ->(type) { resolve_type(types, type) }

        schema.fetch("types").each do |type|
          next if type.fetch("name").start_with?("__")
          type_object = define_type(type, type_resolver)
          types[type["name"]] = type_object
        end

        directives = []
        schema.fetch("directives", []).each do |directive|
          next if GraphQL::Schema.default_directives.include?(directive.fetch("name"))
          directives << define_directive(directive, type_resolver)
        end

        Class.new(GraphQL::Schema) do
          add_type_and_traverse(types.values, root: false)
          orphan_types(types.values.select { |t| t.kind.object? })
          directives(directives)
          description(schema["description"])

          def self.resolve_type(*)
            raise(GraphQL::RequiredImplementationMissingError, "This schema was loaded from string, so it can't resolve types for objects")
          end

          [:query, :mutation, :subscription].each do |root|
            type = schema["#{root}Type"]
            if type
              type_defn = types.fetch(type.fetch("name"))
              self.public_send(root, type_defn)
            end
          end
        end
      end

      NullScalarCoerce = ->(val, _ctx) { val }

      class << self
        private

        def resolve_type(types, type)
          case kind = type.fetch("kind")
          when "ENUM", "INTERFACE", "INPUT_OBJECT", "OBJECT", "SCALAR", "UNION"
            type_name = type.fetch("name")
            type = types[type_name] || Schema::BUILT_IN_TYPES[type_name]
            if type.nil?
              GraphQL::Schema::LateBoundType.new(type_name)
            else
              type
            end
          when "LIST"
            Schema::List.new(resolve_type(types, type.fetch("ofType")))
          when "NON_NULL"
            Schema::NonNull.new(resolve_type(types, type.fetch("ofType")))
          else
            fail GraphQL::RequiredImplementationMissingError, "#{kind} not implemented"
          end
        end

        def extract_default_value(default_value_str, input_value_ast)
          case input_value_ast
          when String, Integer, Float, TrueClass, FalseClass
            input_value_ast
          when GraphQL::Language::Nodes::Enum
            input_value_ast.name
          when GraphQL::Language::Nodes::NullValue
            nil
          when GraphQL::Language::Nodes::InputObject
            input_value_ast.to_h
          when Array
            input_value_ast.map { |element| extract_default_value(default_value_str, element) }
          else
            raise(
              "Encountered unexpected type when loading default value. "\
                    "input_value_ast.class is #{input_value_ast.class} "\
                    "default_value is #{default_value_str}"
            )
          end
        end

        def define_type(type, type_resolver)
          loader = self
          case type.fetch("kind")
          when "ENUM"
            Class.new(GraphQL::Schema::Enum) do
              graphql_name(type["name"])
              description(type["description"])
              type["enumValues"].each do |enum_value|
                value(
                  enum_value["name"],
                  description: enum_value["description"],
                  deprecation_reason: enum_value["deprecationReason"],
                )
              end
            end
          when "INTERFACE"
            Module.new do
              include GraphQL::Schema::Interface
              graphql_name(type["name"])
              description(type["description"])
              loader.build_fields(self, type["fields"] || [], type_resolver)
            end
          when "INPUT_OBJECT"
            Class.new(GraphQL::Schema::InputObject) do
              graphql_name(type["name"])
              description(type["description"])
              loader.build_arguments(self, type["inputFields"], type_resolver)
            end
          when "OBJECT"
            Class.new(GraphQL::Schema::Object) do
              graphql_name(type["name"])
              description(type["description"])
              if type["interfaces"]
                type["interfaces"].each do |interface_type|
                  implements(type_resolver.call(interface_type))
                end
              end
              loader.build_fields(self, type["fields"], type_resolver)
            end
          when "SCALAR"
            type_name = type.fetch("name")
            if (builtin = GraphQL::Schema::BUILT_IN_TYPES[type_name])
              builtin
            else
              Class.new(GraphQL::Schema::Scalar) do
                graphql_name(type["name"])
                description(type["description"])
                specified_by_url(type["specifiedByURL"])
              end
            end
          when "UNION"
            Class.new(GraphQL::Schema::Union) do
              graphql_name(type["name"])
              description(type["description"])
              possible_types(*(type["possibleTypes"].map { |pt| type_resolver.call(pt) }))
            end
          else
            fail GraphQL::RequiredImplementationMissingError, "#{type["kind"]} not implemented"
          end
        end

        def define_directive(directive, type_resolver)
          loader = self
          Class.new(GraphQL::Schema::Directive) do
            graphql_name(directive["name"])
            description(directive["description"])
            locations(*directive["locations"].map(&:to_sym))
            repeatable(directive["isRepeatable"])
            loader.build_arguments(self, directive["args"], type_resolver)
          end
        end

        public

        def build_fields(type_defn, fields, type_resolver)
          loader = self
          fields.each do |field_hash|
            unwrapped_field_hash = field_hash
            while (of_type = unwrapped_field_hash["ofType"])
              unwrapped_field_hash = of_type
            end

            type_defn.field(
              field_hash["name"],
              type: type_resolver.call(field_hash["type"]),
              description: field_hash["description"],
              deprecation_reason: field_hash["deprecationReason"],
              null: true,
              camelize: false,
              connection_extension: nil,
            ) do
              if !field_hash["args"].empty?
                loader.build_arguments(self, field_hash["args"], type_resolver)
              end
            end
          end
        end

        def build_arguments(arg_owner, args, type_resolver)
          args.each do |arg|
            kwargs = {
              type: type_resolver.call(arg["type"]),
              description: arg["description"],
              deprecation_reason: arg["deprecationReason"],
              required: false,
              camelize: false,
            }

            if arg["defaultValue"]
              default_value_str = arg["defaultValue"]

              dummy_query_str = "query getStuff($var: InputObj = #{default_value_str}) { __typename }"

              # Returns a `GraphQL::Language::Nodes::Document`:
              dummy_query_ast = GraphQL.parse(dummy_query_str)

              # Reach into the AST for the default value:
              input_value_ast = dummy_query_ast.definitions.first.variables.first.default_value

              kwargs[:default_value] = extract_default_value(default_value_str, input_value_ast)
            end

            arg_owner.argument(arg["name"], **kwargs)
          end
        end
      end
    end
  end
end
