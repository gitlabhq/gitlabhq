# frozen_string_literal: true
require "graphql/schema/build_from_definition/resolve_map"

module GraphQL
  class Schema
    module BuildFromDefinition
      class << self
        # @see {Schema.from_definition}
        def from_definition(schema_superclass, definition_string, parser: GraphQL.default_parser, **kwargs)
          if defined?(parser::SchemaParser)
            parser = parser::SchemaParser
          end
          from_document(schema_superclass, parser.parse(definition_string), **kwargs)
        end

        def from_definition_path(schema_superclass, definition_path, parser: GraphQL.default_parser, **kwargs)
          if defined?(parser::SchemaParser)
            parser = parser::SchemaParser
          end
          from_document(schema_superclass, parser.parse_file(definition_path), **kwargs)
        end

        def from_document(schema_superclass, document, default_resolve:, using: {}, relay: false)
          Builder.build(schema_superclass, document, default_resolve: default_resolve || {}, relay: relay, using: using)
        end
      end

      # @api private
      module Builder
        include GraphQL::EmptyObjects
        extend self

        def build(schema_superclass, document, default_resolve:, using: {}, relay:)
          raise InvalidDocumentError.new('Must provide a document ast.') if !document || !document.is_a?(GraphQL::Language::Nodes::Document)

          if default_resolve.is_a?(Hash)
            default_resolve = ResolveMap.new(default_resolve)
          end

          schema_defns = document.definitions.select { |d| d.is_a?(GraphQL::Language::Nodes::SchemaDefinition) }
          if schema_defns.size > 1
            raise InvalidDocumentError.new('Must provide only one schema definition.')
          end
          schema_definition = schema_defns.first
          types = {}
          directives = schema_superclass.directives.dup
          type_resolver = build_resolve_type(types, directives, ->(type_name) { types[type_name] ||= Schema::LateBoundType.new(type_name)})
          # Make a different type resolver because we need to coerce directive arguments
          # _while_ building the schema.
          # It will dig for a type if it encounters a custom type. This could be a problem if there are cycles.
          directive_type_resolver = nil
          directive_type_resolver = build_resolve_type(types, directives, ->(type_name) {
            types[type_name] ||= begin
              defn = document.definitions.find { |d| d.respond_to?(:name) && d.name == type_name }
              if defn
                build_definition_from_node(defn, directive_type_resolver, default_resolve)
              elsif (built_in_defn = GraphQL::Schema::BUILT_IN_TYPES[type_name])
                built_in_defn
              else
                raise "No definition for #{type_name.inspect} found in schema document or built-in types. Add a definition for it or remove it."
              end
            end
          })

          directives.merge!(GraphQL::Schema.default_directives)
          document.definitions.each do |definition|
            if definition.is_a?(GraphQL::Language::Nodes::DirectiveDefinition)
              directives[definition.name] = build_directive(definition, directive_type_resolver)
            end
          end

          # In case any directives referenced built-in types for their arguments:
          replace_late_bound_types_with_built_in(types)

          schema_extensions = nil
          document.definitions.each do |definition|
            case definition
            when GraphQL::Language::Nodes::SchemaDefinition, GraphQL::Language::Nodes::DirectiveDefinition
              nil # already handled
            when GraphQL::Language::Nodes::SchemaExtension
              schema_extensions ||= []
              schema_extensions << definition
            else
              # It's possible that this was already loaded by the directives
              prev_type = types[definition.name]
              if prev_type.nil? || prev_type.is_a?(Schema::LateBoundType)
                types[definition.name] = build_definition_from_node(definition, type_resolver, default_resolve)
              end
            end
          end

          replace_late_bound_types_with_built_in(types)

          if schema_definition
            if schema_definition.query
              raise InvalidDocumentError.new("Specified query type \"#{schema_definition.query}\" not found in document.") unless types[schema_definition.query]
              query_root_type = types[schema_definition.query]
            end

            if schema_definition.mutation
              raise InvalidDocumentError.new("Specified mutation type \"#{schema_definition.mutation}\" not found in document.") unless types[schema_definition.mutation]
              mutation_root_type = types[schema_definition.mutation]
            end

            if schema_definition.subscription
              raise InvalidDocumentError.new("Specified subscription type \"#{schema_definition.subscription}\" not found in document.") unless types[schema_definition.subscription]
              subscription_root_type = types[schema_definition.subscription]
            end

            if schema_definition.query.nil? &&
                schema_definition.mutation.nil? &&
                schema_definition.subscription.nil?
              # This schema may have been given with directives only,
              # check for defaults:
              query_root_type = types['Query']
              mutation_root_type = types['Mutation']
              subscription_root_type = types['Subscription']
            end
          else
            query_root_type = types['Query']
            mutation_root_type = types['Mutation']
            subscription_root_type = types['Subscription']
          end

          raise InvalidDocumentError.new('Must provide schema definition with query type or a type named Query.') unless query_root_type

          builder = self

          found_types = types.values
          object_types = found_types.select { |t| t.respond_to?(:kind) && t.kind.object? }
          schema_class = Class.new(schema_superclass) do
            begin
              # Add these first so that there's some chance of resolving late-bound types
              add_type_and_traverse(found_types, root: false)
              orphan_types(object_types)
              query query_root_type
              mutation mutation_root_type
              subscription subscription_root_type
            rescue Schema::UnresolvedLateBoundTypeError  => err
              type_name = err.type.name
              err_backtrace =  err.backtrace
              raise InvalidDocumentError, "Type \"#{type_name}\" not found in document.", err_backtrace
            end

            object_types.each do |t|
              t.interfaces.each do |int_t|
                int_t.orphan_types(t)
              end
            end

            if default_resolve.respond_to?(:resolve_type)
              def self.resolve_type(*args)
                self.definition_default_resolve.resolve_type(*args)
              end
            else
              def self.resolve_type(*args)
                NullResolveType.call(*args)
              end
            end

            directives directives.values

            if schema_definition
              ast_node(schema_definition)
              builder.build_directives(self, schema_definition, type_resolver)
            end

            using.each do |plugin, options|
              if options
                use(plugin, **options)
              else
                use(plugin)
              end
            end

            # Empty `orphan_types` -- this will make unreachable types ... unreachable.
            own_orphan_types.clear

            class << self
              attr_accessor :definition_default_resolve
            end

            self.definition_default_resolve = default_resolve

            def definition_default_resolve
              self.class.definition_default_resolve
            end

            def self.inherited(child_class)
              child_class.definition_default_resolve = self.definition_default_resolve
              super
            end
          end

          if schema_extensions
            schema_extensions.each do |ext|
              build_directives(schema_class, ext, type_resolver)
            end
          end

          schema_class
        end

        NullResolveType = ->(type, obj, ctx) {
          raise(GraphQL::RequiredImplementationMissingError, "Generated Schema cannot use Interface or Union types for execution. Implement resolve_type on your resolver.")
        }

        def build_definition_from_node(definition, type_resolver, default_resolve)
          case definition
          when GraphQL::Language::Nodes::EnumTypeDefinition
            build_enum_type(definition, type_resolver)
          when GraphQL::Language::Nodes::ObjectTypeDefinition
            build_object_type(definition, type_resolver)
          when GraphQL::Language::Nodes::InterfaceTypeDefinition
            build_interface_type(definition, type_resolver)
          when GraphQL::Language::Nodes::UnionTypeDefinition
            build_union_type(definition, type_resolver)
          when GraphQL::Language::Nodes::ScalarTypeDefinition
            build_scalar_type(definition, type_resolver, default_resolve: default_resolve)
          when GraphQL::Language::Nodes::InputObjectTypeDefinition
            build_input_object_type(definition, type_resolver)
          end
        end

        # Modify `types`, replacing any late-bound references to built-in types
        # with their actual definitions.
        #
        # (Schema definitions are allowed to reference those built-ins without redefining them.)
        # @return void
        def replace_late_bound_types_with_built_in(types)
          GraphQL::Schema::BUILT_IN_TYPES.each do |scalar_name, built_in_scalar|
            existing_type = types[scalar_name]
            if existing_type.is_a?(GraphQL::Schema::LateBoundType)
              types[scalar_name] = built_in_scalar
            end
          end
        end

        def build_directives(definition, ast_node, type_resolver)
          dirs = prepare_directives(ast_node, type_resolver)
          dirs.each do |(dir_class, options)|
            if definition.respond_to?(:schema_directive)
              # it's a schema
              definition.schema_directive(dir_class, **options)
            else
              definition.directive(dir_class, **options)
            end
          end
        end

        def prepare_directives(ast_node, type_resolver)
          dirs = []
          ast_node.directives.each do |dir_node|
            if dir_node.name == "deprecated"
              # This is handled using `deprecation_reason`
              next
            else
              dir_class = type_resolver.call(dir_node.name)
              if dir_class.nil?
                raise ArgumentError, "No definition for @#{dir_node.name} #{ast_node.respond_to?(:name) ? "on #{ast_node.name} " : ""}at #{ast_node.line}:#{ast_node.col}"
              end
              options = args_to_kwargs(dir_class, dir_node)
              dirs << [dir_class, options]
            end
          end
          dirs
        end

        def args_to_kwargs(arg_owner, node)
          if node.respond_to?(:arguments)
            kwargs = {}
            node.arguments.each do |arg_node|
              arg_defn = arg_owner.get_argument(arg_node.name)
              kwargs[arg_defn.keyword] = args_to_kwargs(arg_defn.type.unwrap, arg_node.value)
            end
            kwargs
          elsif node.is_a?(Array)
            node.map { |n| args_to_kwargs(arg_owner, n) }
          elsif node.is_a?(Language::Nodes::Enum)
            node.name
          else
            # scalar
            node
          end
        end

        def build_enum_type(enum_type_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Enum) do
            graphql_name(enum_type_definition.name)
            builder.build_directives(self, enum_type_definition, type_resolver)
            description(enum_type_definition.description)
            ast_node(enum_type_definition)
            enum_type_definition.values.each do |enum_value_definition|
              value(enum_value_definition.name,
                value: enum_value_definition.name,
                deprecation_reason: builder.build_deprecation_reason(enum_value_definition.directives),
                description: enum_value_definition.description,
                directives: builder.prepare_directives(enum_value_definition, type_resolver),
                ast_node: enum_value_definition,
              )
            end
          end
        end

        def build_deprecation_reason(directives)
          deprecated_directive = directives.find{ |d| d.name == 'deprecated' }
          return unless deprecated_directive

          reason = deprecated_directive.arguments.find{ |a| a.name == 'reason' }
          return GraphQL::Schema::Directive::DEFAULT_DEPRECATION_REASON unless reason

          reason.value
        end

        def build_scalar_type(scalar_type_definition, type_resolver, default_resolve:)
          builder = self
          Class.new(GraphQL::Schema::Scalar) do
            graphql_name(scalar_type_definition.name)
            description(scalar_type_definition.description)
            ast_node(scalar_type_definition)
            builder.build_directives(self, scalar_type_definition, type_resolver)

            if default_resolve.respond_to?(:coerce_input)
              # Put these method definitions in another method to avoid retaining `type_resolve`
              # from this method's bindiing
              builder.build_scalar_type_coerce_method(self, :coerce_input, default_resolve)
              builder.build_scalar_type_coerce_method(self, :coerce_result, default_resolve)
            end
          end
        end

        def build_scalar_type_coerce_method(scalar_class, method_name, default_definition_resolve)
          scalar_class.define_singleton_method(method_name) do |val, ctx|
            default_definition_resolve.public_send(method_name, self, val, ctx)
          end
        end

        def build_union_type(union_type_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Union) do
            graphql_name(union_type_definition.name)
            description(union_type_definition.description)
            possible_types(*union_type_definition.types.map { |type_name| type_resolver.call(type_name) })
            ast_node(union_type_definition)
            builder.build_directives(self, union_type_definition, type_resolver)
          end
        end

        def build_object_type(object_type_definition, type_resolver)
          builder = self

          Class.new(GraphQL::Schema::Object) do
            graphql_name(object_type_definition.name)
            description(object_type_definition.description)
            ast_node(object_type_definition)
            builder.build_directives(self, object_type_definition, type_resolver)

            object_type_definition.interfaces.each do |interface_name|
              interface_defn = type_resolver.call(interface_name)
              implements(interface_defn)
            end

            builder.build_fields(self, object_type_definition.fields, type_resolver, default_resolve: true)
          end
        end

        def build_input_object_type(input_object_type_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::InputObject) do
            graphql_name(input_object_type_definition.name)
            description(input_object_type_definition.description)
            ast_node(input_object_type_definition)
            builder.build_directives(self, input_object_type_definition, type_resolver)
            builder.build_arguments(self, input_object_type_definition.fields, type_resolver)
          end
        end

        def build_default_value(default_value)
          case default_value
          when GraphQL::Language::Nodes::Enum
            default_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
          when GraphQL::Language::Nodes::InputObject
            default_value.to_h
          when Array
            default_value.map { |v| build_default_value(v) }
          else
            default_value
          end
        end

        def build_arguments(type_class, arguments, type_resolver)
          builder = self

          arguments.each do |argument_defn|
            default_value_kwargs = if !argument_defn.default_value.nil?
              { default_value: builder.build_default_value(argument_defn.default_value) }
            else
              EMPTY_HASH
            end

            type_class.argument(
              argument_defn.name,
              type: type_resolver.call(argument_defn.type),
              required: false,
              description: argument_defn.description,
              deprecation_reason: builder.build_deprecation_reason(argument_defn.directives),
              ast_node: argument_defn,
              camelize: false,
              directives: prepare_directives(argument_defn, type_resolver),
              **default_value_kwargs
            )
          end
        end

        def build_directive(directive_definition, type_resolver)
          builder = self
          Class.new(GraphQL::Schema::Directive) do
            graphql_name(directive_definition.name)
            description(directive_definition.description)
            repeatable(directive_definition.repeatable)
            locations(*directive_definition.locations.map { |location| location.name.to_sym })
            ast_node(directive_definition)
            builder.build_arguments(self, directive_definition.arguments, type_resolver)
          end
        end

        def build_interface_type(interface_type_definition, type_resolver)
          builder = self
          Module.new do
            include GraphQL::Schema::Interface
            graphql_name(interface_type_definition.name)
            description(interface_type_definition.description)
            interface_type_definition.interfaces.each do |interface_name|
              interface_defn = type_resolver.call(interface_name)
              implements(interface_defn)
            end
            ast_node(interface_type_definition)
            builder.build_directives(self, interface_type_definition, type_resolver)

            builder.build_fields(self, interface_type_definition.fields, type_resolver, default_resolve: nil)
          end
        end

        def build_fields(owner, field_definitions, type_resolver, default_resolve:)
          builder = self

          field_definitions.each do |field_definition|
            resolve_method_name = -"resolve_field_#{field_definition.name}"
            schema_field_defn = owner.field(
              field_definition.name,
              description: field_definition.description,
              type: type_resolver.call(field_definition.type),
              null: true,
              connection_extension: nil,
              deprecation_reason: build_deprecation_reason(field_definition.directives),
              ast_node: field_definition,
              method_conflict_warning: false,
              camelize: false,
              directives: prepare_directives(field_definition, type_resolver),
              resolver_method: resolve_method_name,
            )

            builder.build_arguments(schema_field_defn, field_definition.arguments, type_resolver)

            # Don't do this for interfaces
            if default_resolve
              define_field_resolve_method(owner, resolve_method_name, field_definition.name)
            end
          end
        end

        def define_field_resolve_method(owner, method_name, field_name)
          owner.define_method(method_name) { |**args|
            field_instance = self.class.get_field(field_name)
            context.schema.definition_default_resolve.call(self.class, field_instance, object, args, context)
          }
        end

        def build_resolve_type(lookup_hash, directives, missing_type_handler)
          resolve_type_proc = nil
          resolve_type_proc = ->(ast_node) {
            case ast_node
            when GraphQL::Language::Nodes::TypeName
              type_name = ast_node.name
              if lookup_hash.key?(type_name)
                lookup_hash[type_name]
              else
                missing_type_handler.call(type_name)
              end
            when GraphQL::Language::Nodes::NonNullType
              resolve_type_proc.call(ast_node.of_type).to_non_null_type
            when GraphQL::Language::Nodes::ListType
              resolve_type_proc.call(ast_node.of_type).to_list_type
            when String
              directives[ast_node]
            else
              raise "Unexpected ast_node: #{ast_node.inspect}"
            end
          }
          resolve_type_proc
        end
      end

      private_constant :Builder
    end
  end
end
