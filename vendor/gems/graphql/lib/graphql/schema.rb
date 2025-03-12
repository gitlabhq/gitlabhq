# frozen_string_literal: true
require "logger"
require "graphql/schema/addition"
require "graphql/schema/always_visible"
require "graphql/schema/base_64_encoder"
require "graphql/schema/find_inherited_value"
require "graphql/schema/finder"
require "graphql/schema/introspection_system"
require "graphql/schema/late_bound_type"
require "graphql/schema/timeout"
require "graphql/schema/type_expression"
require "graphql/schema/unique_within_type"
require "graphql/schema/warden"
require "graphql/schema/build_from_definition"

require "graphql/schema/validator"
require "graphql/schema/member"
require "graphql/schema/wrapper"
require "graphql/schema/list"
require "graphql/schema/non_null"
require "graphql/schema/argument"
require "graphql/schema/enum_value"
require "graphql/schema/enum"
require "graphql/schema/field_extension"
require "graphql/schema/field"
require "graphql/schema/input_object"
require "graphql/schema/interface"
require "graphql/schema/scalar"
require "graphql/schema/object"
require "graphql/schema/union"
require "graphql/schema/directive"
require "graphql/schema/directive/deprecated"
require "graphql/schema/directive/include"
require "graphql/schema/directive/one_of"
require "graphql/schema/directive/skip"
require "graphql/schema/directive/feature"
require "graphql/schema/directive/flagged"
require "graphql/schema/directive/transform"
require "graphql/schema/directive/specified_by"
require "graphql/schema/type_membership"

require "graphql/schema/resolver"
require "graphql/schema/mutation"
require "graphql/schema/has_single_input_argument"
require "graphql/schema/relay_classic_mutation"
require "graphql/schema/subscription"
require "graphql/schema/visibility"

module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  #
  # The {Schema} contains:
  #
  #  - types for exposing your application
  #  - query analyzers for assessing incoming queries (including max depth & max complexity restrictions)
  #  - execution strategies for running incoming queries
  #
  # Schemas start with root types, {Schema#query}, {Schema#mutation} and {Schema#subscription}.
  # The schema will traverse the tree of fields & types, using those as starting points.
  # Any undiscoverable types may be provided with the `types` configuration.
  #
  # Schemas can restrict large incoming queries with `max_depth` and `max_complexity` configurations.
  # (These configurations can be overridden by specific calls to {Schema#execute})
  #
  # @example defining a schema
  #   class MySchema < GraphQL::Schema
  #     query QueryType
  #     # If types are only connected by way of interfaces, they must be added here
  #     orphan_types ImageType, AudioType
  #   end
  #
  class Schema
    extend GraphQL::Schema::Member::HasAstNode
    extend GraphQL::Schema::FindInheritedValue
    extend Autoload

    autoload :BUILT_IN_TYPES, "graphql/schema/built_in_types"

    class DuplicateNamesError < GraphQL::Error
      attr_reader :duplicated_name
      def initialize(duplicated_name:, duplicated_definition_1:, duplicated_definition_2:)
        @duplicated_name = duplicated_name
        super(
          "Found two visible definitions for `#{duplicated_name}`: #{duplicated_definition_1}, #{duplicated_definition_2}"
        )
      end
    end

    class UnresolvedLateBoundTypeError < GraphQL::Error
      attr_reader :type
      def initialize(type:)
        @type = type
        super("Late bound type was never found: #{type.inspect}")
      end
    end

    # Error that is raised when [#Schema#from_definition] is passed an invalid schema definition string.
    class InvalidDocumentError < Error; end;

    class << self
      # Create schema with the result of an introspection query.
      # @param introspection_result [Hash] A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
      # @return [Class<GraphQL::Schema>] the schema described by `input`
      def from_introspection(introspection_result)
        GraphQL::Schema::Loader.load(introspection_result)
      end

      # Create schema from an IDL schema or file containing an IDL definition.
      # @param definition_or_path [String] A schema definition string, or a path to a file containing the definition
      # @param default_resolve [<#call(type, field, obj, args, ctx)>] A callable for handling field resolution
      # @param parser [Object] An object for handling definition string parsing (must respond to `parse`)
      # @param using [Hash] Plugins to attach to the created schema with `use(key, value)`
      # @return [Class] the schema described by `document`
      def from_definition(definition_or_path, default_resolve: nil, parser: GraphQL.default_parser, using: {})
        # If the file ends in `.graphql` or `.graphqls`, treat it like a filepath
        if definition_or_path.end_with?(".graphql") || definition_or_path.end_with?(".graphqls")
          GraphQL::Schema::BuildFromDefinition.from_definition_path(
            self,
            definition_or_path,
            default_resolve: default_resolve,
            parser: parser,
            using: using,
          )
        else
          GraphQL::Schema::BuildFromDefinition.from_definition(
            self,
            definition_or_path,
            default_resolve: default_resolve,
            parser: parser,
            using: using,
          )
        end
      end

      def deprecated_graphql_definition
        graphql_definition(silence_deprecation_warning: true)
      end

      # @return [GraphQL::Subscriptions]
      def subscriptions(inherited: true)
        defined?(@subscriptions) ? @subscriptions : (inherited ? find_inherited_value(:subscriptions, nil) : nil)
      end

      def subscriptions=(new_implementation)
        @subscriptions = new_implementation
      end

      # @param new_mode [Symbol] If configured, this will be used when `context: { trace_mode: ... }` isn't set.
      def default_trace_mode(new_mode = nil)
        if new_mode
          @default_trace_mode = new_mode
        elsif defined?(@default_trace_mode)
          @default_trace_mode
        elsif superclass.respond_to?(:default_trace_mode)
          superclass.default_trace_mode
        else
          :default
        end
      end

      def trace_class(new_class = nil)
        if new_class
          # If any modules were already added for `:default`,
          # re-apply them here
          mods = trace_modules_for(:default)
          mods.each { |mod| new_class.include(mod) }
          new_class.include(DefaultTraceClass)
          trace_mode(:default, new_class)
        end
        trace_class_for(:default, build: true)
      end

      # @return [Class] Return the trace class to use for this mode, looking one up on the superclass if this Schema doesn't have one defined.
      def trace_class_for(mode, build: false)
        if (trace_class = own_trace_modes[mode])
          trace_class
        elsif superclass.respond_to?(:trace_class_for) && (trace_class = superclass.trace_class_for(mode, build: false))
          trace_class
        elsif build
          own_trace_modes[mode] = build_trace_mode(mode)
        else
          nil
        end
      end

      # Configure `trace_class` to be used whenever `context: { trace_mode: mode_name }` is requested.
      # {default_trace_mode} is used when no `trace_mode: ...` is requested.
      #
      # When a `trace_class` is added this way, it will _not_ receive other modules added with `trace_with(...)`
      # unless `trace_mode` is explicitly given. (This class will not receive any default trace modules.)
      #
      # Subclasses of the schema will use `trace_class` as a base class for this mode and those
      # subclass also will _not_ receive default tracing modules.
      #
      # @param mode_name [Symbol]
      # @param trace_class [Class] subclass of GraphQL::Tracing::Trace
      # @return void
      def trace_mode(mode_name, trace_class)
        own_trace_modes[mode_name] = trace_class
        nil
      end

      def own_trace_modes
        @own_trace_modes ||= {}
      end

      def build_trace_mode(mode)
        case mode
        when :default
          # Use the superclass's default mode if it has one, or else start an inheritance chain at the built-in base class.
          base_class = (superclass.respond_to?(:trace_class_for) && superclass.trace_class_for(mode, build: true)) || GraphQL::Tracing::Trace
          const_set(:DefaultTrace, Class.new(base_class) do
            include DefaultTraceClass
          end)
        else
          # First, see if the superclass has a custom-defined class for this.
          # Then, if it doesn't, use this class's default trace
          base_class = (superclass.respond_to?(:trace_class_for) && superclass.trace_class_for(mode)) || trace_class_for(:default, build: true)
          # Prepare the default trace class if it hasn't been initialized yet
          base_class ||= (own_trace_modes[:default] = build_trace_mode(:default))
          mods = trace_modules_for(mode)
          if base_class < DefaultTraceClass
            mods = trace_modules_for(:default) + mods
          end
          # Copy the existing default options into this mode's options
          default_options = trace_options_for(:default)
          add_trace_options_for(mode, default_options)

          Class.new(base_class) do
            !mods.empty? && include(*mods)
          end
        end
      end

      def own_trace_modules
        @own_trace_modules ||= Hash.new { |h, k| h[k] = [] }
      end

      # @return [Array<Module>] Modules added for tracing in `trace_mode`, including inherited ones
      def trace_modules_for(trace_mode)
        modules = own_trace_modules[trace_mode]
        if superclass.respond_to?(:trace_modules_for)
          modules += superclass.trace_modules_for(trace_mode)
        end
        modules
      end


      # Returns the JSON response of {Introspection::INTROSPECTION_QUERY}.
      # @see {#as_json}
      # @return [String]
      def to_json(**args)
        JSON.pretty_generate(as_json(**args))
      end

      # Return the Hash response of {Introspection::INTROSPECTION_QUERY}.
      # @param context [Hash]
      # @param only [<#call(member, ctx)>]
      # @param except [<#call(member, ctx)>]
      # @param include_deprecated_args [Boolean] If true, deprecated arguments will be included in the JSON response
      # @param include_schema_description [Boolean] If true, the schema's description will be queried and included in the response
      # @param include_is_repeatable [Boolean] If true, `isRepeatable: true|false` will be included with the schema's directives
      # @param include_specified_by_url [Boolean] If true, scalar types' `specifiedByUrl:` will be included in the response
      # @param include_is_one_of [Boolean] If true, `isOneOf: true|false` will be included with input objects
      # @return [Hash] GraphQL result
      def as_json(context: {}, include_deprecated_args: true, include_schema_description: false, include_is_repeatable: false, include_specified_by_url: false, include_is_one_of: false)
        introspection_query = Introspection.query(
          include_deprecated_args: include_deprecated_args,
          include_schema_description: include_schema_description,
          include_is_repeatable: include_is_repeatable,
          include_is_one_of: include_is_one_of,
          include_specified_by_url: include_specified_by_url,
        )

        execute(introspection_query, context: context).to_h
      end

      # Return the GraphQL IDL for the schema
      # @param context [Hash]
      # @return [String]
      def to_definition(context: {})
        GraphQL::Schema::Printer.print_schema(self, context: context)
      end

      # Return the GraphQL::Language::Document IDL AST for the schema
      # @return [GraphQL::Language::Document]
      def to_document
        GraphQL::Language::DocumentFromSchemaDefinition.new(self).document
      end

      # @return [String, nil]
      def description(new_description = nil)
        if new_description
          @description = new_description
        elsif defined?(@description)
          @description
        else
          find_inherited_value(:description, nil)
        end
      end

      def find(path)
        if !@finder
          @find_cache = {}
          @finder ||= GraphQL::Schema::Finder.new(self)
        end
        @find_cache[path] ||= @finder.find(path)
      end

      def static_validator
        GraphQL::StaticValidation::Validator.new(schema: self)
      end

      # Add `plugin` to this schema
      # @param plugin [#use] A Schema plugin
      # @return void
      def use(plugin, **kwargs)
        if !kwargs.empty?
          plugin.use(self, **kwargs)
        else
          plugin.use(self)
        end
        own_plugins << [plugin, kwargs]
      end

      def plugins
        find_inherited_value(:plugins, EMPTY_ARRAY) + own_plugins
      end

      # Build a map of `{ name => type }` and return it
      # @return [Hash<String => Class>] A dictionary of type classes by their GraphQL name
      # @see get_type Which is more efficient for finding _one type_ by name, because it doesn't merge hashes.
      def types(context = GraphQL::Query::NullContext.instance)
        if use_visibility_profile?
          types = Visibility::Profile.from_context(context, self)
          return types.all_types_h
        end
        all_types = non_introspection_types.merge(introspection_system.types)
        visible_types = {}
        all_types.each do |k, v|
          visible_types[k] =if v.is_a?(Array)
            visible_t = nil
            v.each do |t|
              if t.visible?(context)
                if visible_t.nil?
                  visible_t = t
                else
                  raise DuplicateNamesError.new(
                    duplicated_name: k, duplicated_definition_1: visible_t.inspect, duplicated_definition_2: t.inspect
                  )
                end
              end
            end
            visible_t
          else
            v
          end
        end
        visible_types
      end

      # @param type_name [String]
      # @param context [GraphQL::Query::Context] Used for filtering definitions at query-time
      # @param use_visibility_profile Private, for migration to {Schema::Visibility}
      # @return [Module, nil] A type, or nil if there's no type called `type_name`
      def get_type(type_name, context = GraphQL::Query::NullContext.instance, use_visibility_profile = use_visibility_profile?)
        if use_visibility_profile
          return Visibility::Profile.from_context(context, self).type(type_name)
        end
        local_entry = own_types[type_name]
        type_defn = case local_entry
        when nil
          nil
        when Array
          if context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)
            local_entry
          else
            visible_t = nil
            warden = Warden.from_context(context)
            local_entry.each do |t|
              if warden.visible_type?(t, context)
                if visible_t.nil?
                  visible_t = t
                else
                  raise DuplicateNamesError.new(
                    duplicated_name: type_name, duplicated_definition_1: visible_t.inspect, duplicated_definition_2: t.inspect
                  )
                end
              end
            end
            visible_t
          end
        when Module
          local_entry
        else
          raise "Invariant: unexpected own_types[#{type_name.inspect}]: #{local_entry.inspect}"
        end

        type_defn ||
          introspection_system.types[type_name] || # todo context-specific introspection?
          (superclass.respond_to?(:get_type) ? superclass.get_type(type_name, context, use_visibility_profile) : nil)
      end

      # @return [Boolean] Does this schema have _any_ definition for a type named `type_name`, regardless of visibility?
      def has_defined_type?(type_name)
        own_types.key?(type_name) || introspection_system.types.key?(type_name) || (superclass.respond_to?(:has_defined_type?) ? superclass.has_defined_type?(type_name) : false)
      end

      # @api private
      attr_writer :connections

      # @return [GraphQL::Pagination::Connections] if installed
      def connections
        if defined?(@connections)
          @connections
        else
          inherited_connections = find_inherited_value(:connections, nil)
          # This schema is part of an inheritance chain which is using new connections,
          # make a new instance, so we don't pollute the upstream one.
          if inherited_connections
            @connections = Pagination::Connections.new(schema: self)
          else
            nil
          end
        end
      end

      # Get or set the root `query { ... }` object for this schema.
      #
      # @example Using `Types::Query` as the entry-point
      #   query { Types::Query }
      #
      # @param new_query_object [Class<GraphQL::Schema::Object>] The root type to use for queries
      # @param lazy_load_block If a block is given, then it will be called when GraphQL-Ruby needs the root query type.
      # @return [Class<GraphQL::Schema::Object>, nil] The configured query root type, if there is one.
      def query(new_query_object = nil, &lazy_load_block)
        if new_query_object || block_given?
          if @query_object
            dup_defn = new_query_object || yield
            raise GraphQL::Error, "Second definition of `query(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@query_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @query_object = lazy_load_block.call
                self.visibility.query_configured(@query_object)
              else
                @query_object = lazy_load_block
              end
            else
              @query_object = new_query_object
              self.visibility.query_configured(@query_object)
            end
          else
            @query_object = new_query_object || lazy_load_block.call
            add_type_and_traverse(@query_object, root: true)
          end
          nil
        elsif @query_object.is_a?(Proc)
          @query_object = @query_object.call
          self.visibility&.query_configured(@query_object)
          @query_object
        else
          @query_object || find_inherited_value(:query)
        end
      end

      # Get or set the root `mutation { ... }` object for this schema.
      #
      # @example Using `Types::Mutation` as the entry-point
      #   mutation { Types::Mutation }
      #
      # @param new_mutation_object [Class<GraphQL::Schema::Object>] The root type to use for mutations
      # @param lazy_load_block If a block is given, then it will be called when GraphQL-Ruby needs the root mutation type.
      # @return [Class<GraphQL::Schema::Object>, nil] The configured mutation root type, if there is one.
      def mutation(new_mutation_object = nil, &lazy_load_block)
        if new_mutation_object || block_given?
          if @mutation_object
            dup_defn = new_mutation_object || yield
            raise GraphQL::Error, "Second definition of `mutation(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@mutation_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @mutation_object = lazy_load_block.call
                self.visibility.mutation_configured(@mutation_object)
              else
                @mutation_object = lazy_load_block
              end
            else
              @mutation_object = new_mutation_object
              self.visibility.mutation_configured(@mutation_object)
            end
          else
            @mutation_object = new_mutation_object || lazy_load_block.call
            add_type_and_traverse(@mutation_object, root: true)
          end
          nil
        elsif @mutation_object.is_a?(Proc)
          @mutation_object = @mutation_object.call
          self.visibility&.mutation_configured(@mutation_object)
          @mutation_object
        else
          @mutation_object || find_inherited_value(:mutation)
        end
      end

      # Get or set the root `subscription { ... }` object for this schema.
      #
      # @example Using `Types::Subscription` as the entry-point
      #   subscription { Types::Subscription }
      #
      # @param new_subscription_object [Class<GraphQL::Schema::Object>] The root type to use for subscriptions
      # @param lazy_load_block If a block is given, then it will be called when GraphQL-Ruby needs the root subscription type.
      # @return [Class<GraphQL::Schema::Object>, nil] The configured subscription root type, if there is one.
      def subscription(new_subscription_object = nil, &lazy_load_block)
        if new_subscription_object || block_given?
          if @subscription_object
            dup_defn = new_subscription_object || yield
            raise GraphQL::Error, "Second definition of `subscription(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@subscription_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @subscription_object = lazy_load_block.call
                visibility.subscription_configured(@subscription_object)
              else
                @subscription_object = lazy_load_block
              end
            else
              @subscription_object = new_subscription_object
              self.visibility.subscription_configured(@subscription_object)
            end
            add_subscription_extension_if_necessary
          else
            @subscription_object = new_subscription_object || lazy_load_block.call
            add_subscription_extension_if_necessary
            add_type_and_traverse(@subscription_object, root: true)
          end
          nil
        elsif @subscription_object.is_a?(Proc)
          @subscription_object = @subscription_object.call
          add_subscription_extension_if_necessary
          self.visibility.subscription_configured(@subscription_object)
          @subscription_object
        else
          @subscription_object || find_inherited_value(:subscription)
        end
      end

      # @api private
      def root_type_for_operation(operation)
        case operation
        when "query"
          query
        when "mutation"
          mutation
        when "subscription"
          subscription
        else
          raise ArgumentError, "unknown operation type: #{operation}"
        end
      end

      # @return [Array<Class>] The root types (query, mutation, subscription) defined for this schema
      def root_types
        if use_visibility_profile?
          [query, mutation, subscription].compact
        else
          @root_types
        end
      end

      # @api private
      def warden_class
        if defined?(@warden_class)
          @warden_class
        elsif superclass.respond_to?(:warden_class)
          superclass.warden_class
        else
          GraphQL::Schema::Warden
        end
      end

      # @api private
      attr_writer :warden_class

      # @api private
      def visibility_profile_class
        if defined?(@visibility_profile_class)
          @visibility_profile_class
        elsif superclass.respond_to?(:visibility_profile_class)
          superclass.visibility_profile_class
        else
          GraphQL::Schema::Visibility::Profile
        end
      end

      # @api private
      attr_writer :visibility_profile_class, :use_visibility_profile
      # @api private
      attr_accessor :visibility
      # @api private
      def use_visibility_profile?
        if defined?(@use_visibility_profile)
          @use_visibility_profile
        elsif superclass.respond_to?(:use_visibility_profile?)
          superclass.use_visibility_profile?
        else
          false
        end
      end

      # @param type [Module] The type definition whose possible types you want to see
      # @param context [GraphQL::Query::Context] used for filtering visible possible types at runtime
      # @param use_visibility_profile Private, for migration to {Schema::Visibility}
      # @return [Hash<String, Module>] All possible types, if no `type` is given.
      # @return [Array<Module>] Possible types for `type`, if it's given.
      def possible_types(type = nil, context = GraphQL::Query::NullContext.instance, use_visibility_profile = use_visibility_profile?)
        if use_visibility_profile
          if type
            return Visibility::Profile.from_context(context, self).possible_types(type)
          else
            raise "Schema.possible_types is not implemented for `use_visibility_profile?`"
          end
        end
        if type
          # TODO duck-typing `.possible_types` would probably be nicer here
          if type.kind.union?
            type.possible_types(context: context)
          else
            stored_possible_types = own_possible_types[type]
            visible_possible_types = if stored_possible_types && type.kind.interface?
              stored_possible_types.select do |possible_type|
                possible_type.interfaces(context).include?(type)
              end
            else
              stored_possible_types
            end
            visible_possible_types ||
              introspection_system.possible_types[type] ||
              (
                superclass.respond_to?(:possible_types) ?
                  superclass.possible_types(type, context, use_visibility_profile) :
                  EMPTY_ARRAY
              )
          end
        else
          find_inherited_value(:possible_types, EMPTY_HASH)
            .merge(own_possible_types)
            .merge(introspection_system.possible_types)
        end
      end

      def union_memberships(type = nil)
        if type
          own_um = own_union_memberships.fetch(type.graphql_name, EMPTY_ARRAY)
          inherited_um = find_inherited_value(:union_memberships, EMPTY_HASH).fetch(type.graphql_name, EMPTY_ARRAY)
          own_um + inherited_um
        else
          joined_um = own_union_memberships.dup
          find_inherited_value(:union_memberhips, EMPTY_HASH).each do |k, v|
            um = joined_um[k] ||= []
            um.concat(v)
          end
          joined_um
        end
      end

      # @api private
      # @see GraphQL::Dataloader
      def dataloader_class
        @dataloader_class || GraphQL::Dataloader::NullDataloader
      end

      attr_writer :dataloader_class

      def references_to(to_type = nil, from: nil)
        if to_type
          if from
            refs = own_references_to[to_type] ||= []
            refs << from
          else
            get_references_to(to_type) || EMPTY_ARRAY
          end
        else
          # `@own_references_to` can be quite large for big schemas,
          # and generally speaking, we won't inherit any values.
          # So optimize the most common case -- don't create a duplicate Hash.
          inherited_value = find_inherited_value(:references_to, EMPTY_HASH)
          if !inherited_value.empty?
            inherited_value.merge(own_references_to)
          else
            own_references_to
          end
        end
      end

      def type_from_ast(ast_node, context: self.query_class.new(self, "{ __typename }").context)
        GraphQL::Schema::TypeExpression.build_type(context.query.types, ast_node)
      end

      def get_field(type_or_name, field_name, context = GraphQL::Query::NullContext.instance)
        parent_type = case type_or_name
        when LateBoundType
          get_type(type_or_name.name, context)
        when String
          get_type(type_or_name, context)
        when Module
          type_or_name
        else
          raise GraphQL::InvariantError, "Unexpected field owner for #{field_name.inspect}: #{type_or_name.inspect} (#{type_or_name.class})"
        end

        if parent_type.kind.fields? && (field = parent_type.get_field(field_name, context))
          field
        elsif parent_type == query && (entry_point_field = introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
      end

      def get_fields(type, context = GraphQL::Query::NullContext.instance)
        type.fields(context)
      end

      # Pass a custom introspection module here to use it for this schema.
      # @param new_introspection_namespace [Module] If given, use this module for custom introspection on the schema
      # @return [Module, nil] The configured namespace, if there is one
      def introspection(new_introspection_namespace = nil)
        if new_introspection_namespace
          @introspection = new_introspection_namespace
          # reset this cached value:
          @introspection_system = nil
          introspection_system
          @introspection
        else
          @introspection || find_inherited_value(:introspection)
        end
      end

      # @return [Schema::IntrospectionSystem] Based on {introspection}
      def introspection_system
        if !@introspection_system
          @introspection_system = Schema::IntrospectionSystem.new(self)
          @introspection_system.resolve_late_bindings
          self.visibility&.introspection_system_configured(@introspection_system)
        end
        @introspection_system
      end

      def cursor_encoder(new_encoder = nil)
        if new_encoder
          @cursor_encoder = new_encoder
        end
        @cursor_encoder || find_inherited_value(:cursor_encoder, Base64Encoder)
      end

      def default_max_page_size(new_default_max_page_size = nil)
        if new_default_max_page_size
          @default_max_page_size = new_default_max_page_size
        else
          @default_max_page_size || find_inherited_value(:default_max_page_size)
        end
      end

      # A limit on the number of tokens to accept on incoming query strings.
      # Use this to prevent parsing maliciously-large query strings.
      # @return [nil, Integer]
      def max_query_string_tokens(new_max_tokens = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_max_tokens)
          defined?(@max_query_string_tokens) ? @max_query_string_tokens : find_inherited_value(:max_query_string_tokens)
        else
          @max_query_string_tokens = new_max_tokens
        end
      end

      def default_page_size(new_default_page_size = nil)
        if new_default_page_size
          @default_page_size = new_default_page_size
        else
          @default_page_size || find_inherited_value(:default_page_size)
        end
      end

      def query_execution_strategy(new_query_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.query_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
          warn "  #{caller(1, 1).first}"
        end
        if new_query_execution_strategy
          @query_execution_strategy = new_query_execution_strategy
        else
          @query_execution_strategy || (superclass.respond_to?(:query_execution_strategy) ? superclass.query_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      def mutation_execution_strategy(new_mutation_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.mutation_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
            warn "  #{caller(1, 1).first}"
        end
        if new_mutation_execution_strategy
          @mutation_execution_strategy = new_mutation_execution_strategy
        else
          @mutation_execution_strategy || (superclass.respond_to?(:mutation_execution_strategy) ? superclass.mutation_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      def subscription_execution_strategy(new_subscription_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.subscription_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
          warn "  #{caller(1, 1).first}"
        end
        if new_subscription_execution_strategy
          @subscription_execution_strategy = new_subscription_execution_strategy
        else
          @subscription_execution_strategy || (superclass.respond_to?(:subscription_execution_strategy) ? superclass.subscription_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      attr_writer :validate_timeout

      def validate_timeout(new_validate_timeout = nil)
        if new_validate_timeout
          @validate_timeout = new_validate_timeout
        elsif defined?(@validate_timeout)
          @validate_timeout
        else
          find_inherited_value(:validate_timeout)
        end
      end

      # Validate a query string according to this schema.
      # @param string_or_document [String, GraphQL::Language::Nodes::Document]
      # @return [Array<GraphQL::StaticValidation::Error >]
      def validate(string_or_document, rules: nil, context: nil)
        doc = if string_or_document.is_a?(String)
          GraphQL.parse(string_or_document)
        else
          string_or_document
        end
        query = query_class.new(self, document: doc, context: context)
        validator_opts = { schema: self }
        rules && (validator_opts[:rules] = rules)
        validator = GraphQL::StaticValidation::Validator.new(**validator_opts)
        res = validator.validate(query, timeout: validate_timeout, max_errors: validate_max_errors)
        res[:errors]
      end

      # @param new_query_class [Class<GraphQL::Query>] A subclass to use when executing queries
      def query_class(new_query_class = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_query_class)
          @query_class || (superclass.respond_to?(:query_class) ? superclass.query_class : GraphQL::Query)
        else
          @query_class = new_query_class
        end
      end

      attr_writer :validate_max_errors

      def validate_max_errors(new_validate_max_errors = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_validate_max_errors)
          defined?(@validate_max_errors) ? @validate_max_errors : find_inherited_value(:validate_max_errors)
        else
          @validate_max_errors = new_validate_max_errors
        end
      end

      attr_writer :max_complexity

      def max_complexity(max_complexity = nil, count_introspection_fields: true)
        if max_complexity
          @max_complexity = max_complexity
          @max_complexity_count_introspection_fields = count_introspection_fields
        elsif defined?(@max_complexity)
          @max_complexity
        else
          find_inherited_value(:max_complexity)
        end
      end

      def max_complexity_count_introspection_fields
        if defined?(@max_complexity_count_introspection_fields)
          @max_complexity_count_introspection_fields
        else
          find_inherited_value(:max_complexity_count_introspection_fields, true)
        end
      end

      attr_writer :analysis_engine

      def analysis_engine
        @analysis_engine || find_inherited_value(:analysis_engine, self.default_analysis_engine)
      end

      def error_bubbling(new_error_bubbling = nil)
        if !new_error_bubbling.nil?
          warn("error_bubbling(#{new_error_bubbling.inspect}) is deprecated; the default value of `false` will be the only option in GraphQL-Ruby 3.0")
          @error_bubbling = new_error_bubbling
        else
          @error_bubbling.nil? ? find_inherited_value(:error_bubbling) : @error_bubbling
        end
      end

      attr_writer :error_bubbling

      attr_writer :max_depth

      def max_depth(new_max_depth = nil, count_introspection_fields: true)
        if new_max_depth
          @max_depth = new_max_depth
          @count_introspection_fields = count_introspection_fields
        elsif defined?(@max_depth)
          @max_depth
        else
          find_inherited_value(:max_depth)
        end
      end

      def count_introspection_fields
        if defined?(@count_introspection_fields)
          @count_introspection_fields
        else
          find_inherited_value(:count_introspection_fields, true)
        end
      end

      def disable_introspection_entry_points
        @disable_introspection_entry_points = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_schema_introspection_entry_point
        @disable_schema_introspection_entry_point = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_type_introspection_entry_point
        @disable_type_introspection_entry_point = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_introspection_entry_points?
        if instance_variable_defined?(:@disable_introspection_entry_points)
          @disable_introspection_entry_points
        else
          find_inherited_value(:disable_introspection_entry_points?, false)
        end
      end

      def disable_schema_introspection_entry_point?
        if instance_variable_defined?(:@disable_schema_introspection_entry_point)
          @disable_schema_introspection_entry_point
        else
          find_inherited_value(:disable_schema_introspection_entry_point?, false)
        end
      end

      def disable_type_introspection_entry_point?
        if instance_variable_defined?(:@disable_type_introspection_entry_point)
          @disable_type_introspection_entry_point
        else
          find_inherited_value(:disable_type_introspection_entry_point?, false)
        end
      end

      # @param new_extra_types [Module] Type definitions to include in printing and introspection, even though they aren't referenced in the schema
      # @return [Array<Module>] Type definitions added to this schema
      def extra_types(*new_extra_types)
        if !new_extra_types.empty?
          new_extra_types = new_extra_types.flatten
          @own_extra_types ||= []
          @own_extra_types.concat(new_extra_types)
        end
        inherited_et = find_inherited_value(:extra_types, nil)
        if inherited_et
          if @own_extra_types
            inherited_et + @own_extra_types
          else
            inherited_et
          end
        else
          @own_extra_types || EMPTY_ARRAY
        end
      end

      # Tell the schema about these types so that they can be registered as implementations of interfaces in the schema.
      #
      # This method must be used when an object type is connected to the schema as an interface implementor but
      # not as a return type of a field. In that case, if the object type isn't registered here, GraphQL-Ruby won't be able to find it.
      #
      # @param new_orphan_types [Array<Class<GraphQL::Schema::Object>>] Object types to register as implementations of interfaces in the schema.
      # @return [Array<Class<GraphQL::Schema::Object>>] All previously-registered orphan types for this schema
      def orphan_types(*new_orphan_types)
        if !new_orphan_types.empty?
          new_orphan_types = new_orphan_types.flatten
          non_object_types = new_orphan_types.reject { |ot| ot.is_a?(Class) && ot < GraphQL::Schema::Object }
          if !non_object_types.empty?
            raise ArgumentError, <<~ERR
              Only object type classes should be added as `orphan_types(...)`.

              - Remove these no-op types from `orphan_types`: #{non_object_types.map { |t| "#{t.inspect} (#{t.kind.name})"}.join(", ")}
              - See https://graphql-ruby.org/type_definitions/interfaces.html#orphan-types

              To add other types to your schema, you might want `extra_types`: https://graphql-ruby.org/schema/definition.html#extra-types
            ERR
          end
          add_type_and_traverse(new_orphan_types, root: false) unless use_visibility_profile?
          own_orphan_types.concat(new_orphan_types.flatten)
          self.visibility&.orphan_types_configured(new_orphan_types)
        end

        inherited_ot = find_inherited_value(:orphan_types, nil)
        if inherited_ot
          if !own_orphan_types.empty?
            inherited_ot + own_orphan_types
          else
            inherited_ot
          end
        else
          own_orphan_types
        end
      end

      def default_execution_strategy
        if superclass <= GraphQL::Schema
          superclass.default_execution_strategy
        else
          @default_execution_strategy ||= GraphQL::Execution::Interpreter
        end
      end

      def default_analysis_engine
        if superclass <= GraphQL::Schema
          superclass.default_analysis_engine
        else
          @default_analysis_engine ||= GraphQL::Analysis::AST
        end
      end


      # @param new_default_logger [#log] Something to use for logging messages
      def default_logger(new_default_logger = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_default_logger)
          if defined?(@default_logger)
            @default_logger
          elsif superclass.respond_to?(:default_logger)
            superclass.default_logger
          elsif defined?(Rails) && Rails.respond_to?(:logger) && (rails_logger = Rails.logger)
            rails_logger
          else
            def_logger = Logger.new($stdout)
            def_logger.info! # It doesn't output debug info by default
            def_logger
          end
        elsif new_default_logger == nil
          @default_logger = Logger.new(IO::NULL)
        else
          @default_logger = new_default_logger
        end
      end

      # @param new_context_class [Class<GraphQL::Query::Context>] A subclass to use when executing queries
      def context_class(new_context_class = nil)
        if new_context_class
          @context_class = new_context_class
        else
          @context_class || find_inherited_value(:context_class, GraphQL::Query::Context)
        end
      end

      # Register a handler for errors raised during execution. The handlers can return a new value or raise a new error.
      #
      # @example Handling "not found" with a client-facing error
      #   rescue_from(ActiveRecord::NotFound) { raise GraphQL::ExecutionError, "An object could not be found" }
      #
      # @param err_classes [Array<StandardError>] Classes which should be rescued by `handler_block`
      # @param handler_block The code to run when one of those errors is raised during execution
      # @yieldparam error [StandardError] An instance of one of the configured `err_classes`
      # @yieldparam object [Object] The current application object in the query when the error was raised
      # @yieldparam arguments [GraphQL::Query::Arguments] The current field arguments when the error was raised
      # @yieldparam context [GraphQL::Query::Context] The context for the currently-running operation
      # @yieldreturn [Object] Some object to use in the place where this error was raised
      # @raise [GraphQL::ExecutionError] In the handler, raise to add a client-facing error to the response
      # @raise [StandardError] In the handler, raise to crash the query with a developer-facing error
      def rescue_from(*err_classes, &handler_block)
        err_classes.each do |err_class|
          Execution::Errors.register_rescue_from(err_class, error_handlers[:subclass_handlers], handler_block)
        end
      end

      NEW_HANDLER_HASH = ->(h, k) {
        h[k] = {
          class: k,
          handler: nil,
          subclass_handlers: Hash.new(&NEW_HANDLER_HASH),
         }
      }

      def error_handlers
        @error_handlers ||= {
          class: nil,
          handler: nil,
          subclass_handlers: Hash.new(&NEW_HANDLER_HASH),
        }
      end

      # @api private
      attr_accessor :using_backtrace

      # @api private
      def handle_or_reraise(context, err)
        handler = Execution::Errors.find_handler_for(self, err.class)
        if handler
          obj = context[:current_object]
          args = context[:current_arguments]
          args = args && args.respond_to?(:keyword_arguments) ? args.keyword_arguments : nil
          field = context[:current_field]
          if obj.is_a?(GraphQL::Schema::Object)
            obj = obj.object
          end
          handler[:handler].call(err, obj, args, context, field)
        else
          if (context[:backtrace] || using_backtrace) && !err.is_a?(GraphQL::ExecutionError)
            err = GraphQL::Backtrace::TracedError.new(err, context)
          end

          raise err
        end
      end

      # rubocop:disable Lint/DuplicateMethods
      module ResolveTypeWithType
        def resolve_type(type, obj, ctx)
          maybe_lazy_resolve_type_result = if type.is_a?(Module) && type.respond_to?(:resolve_type)
            type.resolve_type(obj, ctx)
          else
            super
          end

          after_lazy(maybe_lazy_resolve_type_result) do |resolve_type_result|
            if resolve_type_result.is_a?(Array) && resolve_type_result.size == 2
              resolved_type = resolve_type_result[0]
              resolved_value = resolve_type_result[1]
            else
              resolved_type = resolve_type_result
              resolved_value = obj
            end

            if resolved_type.nil? || (resolved_type.is_a?(Module) && resolved_type.respond_to?(:kind))
              [resolved_type, resolved_value]
            else
              raise ".resolve_type should return a type definition, but got #{resolved_type.inspect} (#{resolved_type.class}) from `resolve_type(#{type}, #{obj}, #{ctx})`"
            end
          end
        end
      end

      # GraphQL-Ruby calls this method during execution when it needs the application to determine the type to use for an object.
      #
      # Usually, this object was returned from a field whose return type is an {GraphQL::Schema::Interface} or a {GraphQL::Schema::Union}.
      # But this method is called in other cases, too -- for example, when {GraphQL::Schema::Argument.loads} cases an object to be directly loaded from the database.
      #
      # @example Returning a GraphQL type based on the object's class name
      #   class MySchema < GraphQL::Schema
      #     def resolve_type(_abs_type, object, _context)
      #       graphql_type_name = "Types::#{object.class.name}Type"
      #       graphql_type_name.constantize # If this raises a NameError, then come implement special cases in this method
      #     end
      #   end
      # @param abstract_type [Class, Module, nil] The Interface or Union type which is being resolved, if there is one
      # @param application_object [Object] The object returned from a field whose type must be determined
      # @param context [GraphQL::Query::Context] The query context for the currently-executing query
      # @return [Class<GraphQL::Schema::Object] The Object type definition to use for `obj`
      def resolve_type(abstract_type, application_object, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.resolve_type(abstract_type, application_object, context) must be implemented to use Union types, Interface types, or `loads:` (tried to resolve: #{abstract_type.name})"
      end
      # rubocop:enable Lint/DuplicateMethods

      def inherited(child_class)
        if self == GraphQL::Schema
          child_class.directives(default_directives.values)
          child_class.extend(SubclassGetReferencesTo)
        end
        # Make sure the child class has these built out, so that
        # subclasses can be modified by later calls to `trace_with`
        own_trace_modes.each do |name, _class|
          child_class.own_trace_modes[name] = child_class.build_trace_mode(name)
        end
        child_class.singleton_class.prepend(ResolveTypeWithType)

        if use_visibility_profile?
          vis = self.visibility
          child_class.visibility = vis.dup_for(child_class)
        end
        super
      end

      # Fetch an object based on an incoming ID and the current context. This method should return an object
      # from your application, or return `nil` if there is no object or the object shouldn't be available to this operation.
      #
      # @example Fetching an object with Rails's GlobalID
      #   def self.object_from_id(object_id, _context)
      #     GlobalID.find(global_id)
      #     # TODO: use `context[:current_user]` to determine if this object is authorized.
      #   end
      # @param object_id [String] The ID to fetch an object for. This may be client-provided (as in `node(id: ...)` or `loads:`) or previously stored by the schema (eg, by the `ObjectCache`)
      # @param context [GraphQL::Query::Context] The context for the currently-executing operation
      # @return [Object, nil] The application which `object_id` references, or `nil` if there is no object or the current operation shouldn't have access to the object
      # @see id_from_object which produces these IDs
      def object_from_id(object_id, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.object_from_id(object_id, context) must be implemented to load by ID (tried to load from id `#{object_id}`)"
      end

      # Return a stable ID string for `object` so that it can be refetched later, using {.object_from_id}.
      #
      # {GlobalID}(https://github.com/rails/globalid) and {SQIDs}(https://sqids.org/ruby) can both be used to create IDs.
      #
      # @example Using Rails's GlobalID to generate IDs
      #   def self.id_from_object(application_object, graphql_type, context)
      #     application_object.to_gid_param
      #   end
      #
      # @param application_object [Object] Some object encountered by GraphQL-Ruby while running a query
      # @param graphql_type [Class, Module] The type that GraphQL-Ruby is using for `application_object` during this query
      # @param context [GraphQL::Query::Context] The context for the operation that is currently running
      # @return [String] A stable identifier which can be passed to {.object_from_id} later to re-fetch `application_object`
      def id_from_object(application_object, graphql_type, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.id_from_object(application_object, graphql_type, context) must be implemented to create global ids (tried to create an id for `#{application_object.inspect}`)"
      end

      def visible?(member, ctx)
        member.visible?(ctx)
      end

      def schema_directive(dir_class, **options)
        @own_schema_directives ||= []
        Member::HasDirectives.add_directive(self, @own_schema_directives, dir_class, options)
      end

      def schema_directives
        Member::HasDirectives.get_directives(self, @own_schema_directives, :schema_directives)
      end

      # Called when a type is needed by name at runtime
      def load_type(type_name, ctx)
        get_type(type_name, ctx)
      end
      # This hook is called when an object fails an `authorized?` check.
      # You might report to your bug tracker here, so you can correct
      # the field resolvers not to return unauthorized objects.
      #
      # By default, this hook just replaces the unauthorized object with `nil`.
      #
      # Whatever value is returned from this method will be used instead of the
      # unauthorized object (accessible as `unauthorized_error.object`). If an
      # error is raised, then `nil` will be used.
      #
      # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
      # in this hook.
      #
      # @param unauthorized_error [GraphQL::UnauthorizedError]
      # @return [Object] The returned object will be put in the GraphQL response
      def unauthorized_object(unauthorized_error)
        nil
      end

      # This hook is called when a field fails an `authorized?` check.
      #
      # By default, this hook implements the same behavior as unauthorized_object.
      #
      # Whatever value is returned from this method will be used instead of the
      # unauthorized field . If an error is raised, then `nil` will be used.
      #
      # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
      # in this hook.
      #
      # @param unauthorized_error [GraphQL::UnauthorizedFieldError]
      # @return [Field] The returned field will be put in the GraphQL response
      def unauthorized_field(unauthorized_error)
        unauthorized_object(unauthorized_error)
      end

      # Called at runtime when GraphQL-Ruby encounters a mismatch between the application behavior
      # and the GraphQL type system.
      #
      # The default implementation of this method is to follow the GraphQL specification,
      # but you can override this to report errors to your bug tracker or customize error handling.
      # @param type_error [GraphQL::Error] several specific error classes are passed here, see the default implementation for details
      # @param context [GraphQL::Query::Context] the context for the currently-running operation
      # @return [void]
      # @raise [GraphQL::ExecutionError] to return this error to the client
      # @raise [GraphQL::Error] to crash the query and raise a developer-facing error
      def type_error(type_error, ctx)
        case type_error
        when GraphQL::InvalidNullError
          execution_error = GraphQL::ExecutionError.new(type_error.message, ast_node: type_error.ast_node)
          execution_error.path = ctx[:current_path]

          ctx.errors << execution_error
        when GraphQL::UnresolvedTypeError, GraphQL::StringEncodingError, GraphQL::IntegerEncodingError
          raise type_error
        when GraphQL::IntegerDecodingError
          nil
        end
      end

      # A function to call when {#execute} receives an invalid query string
      #
      # The default is to add the error to `context.errors`
      # @param parse_err [GraphQL::ParseError] The error encountered during parsing
      # @param ctx [GraphQL::Query::Context] The context for the query where the error occurred
      # @return void
      def parse_error(parse_err, ctx)
        ctx.errors.push(parse_err)
      end

      def lazy_resolve(lazy_class, value_method)
        lazy_methods.set(lazy_class, value_method)
      end

      def instrument(instrument_step, instrumenter, options = {})
        warn <<~WARN
        Schema.instrument is deprecated, use `trace_with` instead: https://graphql-ruby.org/queries/tracing.html"
          (From `#{self}.instrument(#{instrument_step}, #{instrumenter})` at #{caller(1, 1).first})

        WARN
        trace_with(Tracing::LegacyHooksTrace)
        own_instrumenters[instrument_step] << instrumenter
      end

      # Add several directives at once
      # @param new_directives [Class]
      def directives(*new_directives)
        if !new_directives.empty?
          new_directives.flatten.each { |d| directive(d) }
        end

        inherited_dirs = find_inherited_value(:directives, default_directives)
        if !own_directives.empty?
          inherited_dirs.merge(own_directives)
        else
          inherited_dirs
        end
      end

      # Attach a single directive to this schema
      # @param new_directive [Class]
      # @return void
      def directive(new_directive)
        if use_visibility_profile?
          own_directives[new_directive.graphql_name] = new_directive
        else
          add_type_and_traverse(new_directive, root: false)
        end
      end

      def default_directives
        @default_directives ||= {
          "include" => GraphQL::Schema::Directive::Include,
          "skip" => GraphQL::Schema::Directive::Skip,
          "deprecated" => GraphQL::Schema::Directive::Deprecated,
          "oneOf" => GraphQL::Schema::Directive::OneOf,
          "specifiedBy" => GraphQL::Schema::Directive::SpecifiedBy,
        }.freeze
      end

      # @return [GraphQL::Tracing::DetailedTrace] if it has been configured for this schema
      attr_accessor :detailed_trace

      # @param query [GraphQL::Query, GraphQL::Execution::Multiplex] Called with a multiplex when multiple queries are executed at once (with {.multiplex})
      # @return [Boolean] When `true`, save a detailed trace for this query.
      # @see Tracing::DetailedTrace DetailedTrace saves traces when this method returns true
      def detailed_trace?(query)
        raise "#{self} must implement `def.detailed_trace?(query)` to use DetailedTrace. Implement this method in your schema definition."
      end

      def tracer(new_tracer, silence_deprecation_warning: false)
        if !silence_deprecation_warning
          warn("`Schema.tracer(#{new_tracer.inspect})` is deprecated; use module-based `trace_with` instead. See: https://graphql-ruby.org/queries/tracing.html")
          warn "  #{caller(1, 1).first}"
        end
        default_trace = trace_class_for(:default, build: true)
        if default_trace.nil? || !(default_trace < GraphQL::Tracing::CallLegacyTracers)
          trace_with(GraphQL::Tracing::CallLegacyTracers)
        end

        own_tracers << new_tracer
      end

      def tracers
        find_inherited_value(:tracers, EMPTY_ARRAY) + own_tracers
      end

      # Mix `trace_mod` into this schema's `Trace` class so that its methods will be called at runtime.
      #
      # You can attach a module to run in only _some_ circumstances by using `mode:`. When a module is added with `mode:`,
      # it will only run for queries with a matching `context[:trace_mode]`.
      #
      # Any custom trace modes _also_ include the default `trace_with ...` modules (that is, those added _without_ any particular `mode: ...` configuration).
      #
      # @example Adding a trace in a special mode
      #   # only runs when `query.context[:trace_mode]` is `:special`
      #   trace_with SpecialTrace, mode: :special
      #
      # @param trace_mod [Module] A module that implements tracing methods
      # @param mode [Symbol] Trace module will only be used for this trade mode
      # @param options [Hash] Keywords that will be passed to the tracing class during `#initialize`
      # @return [void]
      # @see GraphQL::Tracing::Trace Tracing::Trace for available tracing methods
      def trace_with(trace_mod, mode: :default, **options)
        if mode.is_a?(Array)
          mode.each { |m| trace_with(trace_mod, mode: m, **options) }
        else
          tc = own_trace_modes[mode] ||= build_trace_mode(mode)
          tc.include(trace_mod)
          own_trace_modules[mode] << trace_mod
          add_trace_options_for(mode, options)
          if mode == :default
            # This module is being added as a default tracer. If any other mode classes
            # have already been created, but get their default behavior from a superclass,
            # Then mix this into this schema's subclass.
            # (But don't mix it into mode classes that aren't default-based.)
            own_trace_modes.each do |other_mode_name, other_mode_class|
              if other_mode_class < DefaultTraceClass
                # Don't add it back to the inheritance tree if it's already there
                if !(other_mode_class < trace_mod)
                  other_mode_class.include(trace_mod)
                end
                # Add any options so they'll be available
                add_trace_options_for(other_mode_name, options)
              end
            end
          end
        end
        nil
      end

      # The options hash for this trace mode
      # @return [Hash]
      def trace_options_for(mode)
        @trace_options_for_mode ||= {}
        @trace_options_for_mode[mode] ||= begin
          # It may be time to create an options hash for a mode that wasn't registered yet.
          # Mix in the default options in that case.
          default_options = mode == :default ? EMPTY_HASH : trace_options_for(:default)
          # Make sure this returns a new object so that other hashes aren't modified later
          if superclass.respond_to?(:trace_options_for)
            superclass.trace_options_for(mode).merge(default_options)
          else
            default_options.dup
          end
        end
      end

      # Create a trace instance which will include the trace modules specified for the optional mode.
      #
      # If no `mode:` is given, then {default_trace_mode} will be used.
      #
      # If this schema is using {Tracing::DetailedTrace} and {.detailed_trace?} returns `true`, then
      # DetailedTrace's mode will override the passed-in `mode`.
      #
      # @param mode [Symbol] Trace modules for this trade mode will be included
      # @param options [Hash] Keywords that will be passed to the tracing class during `#initialize`
      # @return [Tracing::Trace]
      def new_trace(mode: nil, **options)
        should_sample = if detailed_trace
          if (query = options[:query])
            detailed_trace?(query)
          elsif (multiplex = options[:multiplex])
            if multiplex.queries.length == 1
              detailed_trace?(multiplex.queries.first)
            else
              detailed_trace?(multiplex)
            end
          end
        else
          false
        end

        if should_sample
          mode = detailed_trace.trace_mode
        else
          target = options[:query] || options[:multiplex]
          mode ||= target && target.context[:trace_mode]
        end

        trace_mode = mode || default_trace_mode
        base_trace_options = trace_options_for(trace_mode)
        trace_options = base_trace_options.merge(options)
        trace_class_for_mode = trace_class_for(trace_mode, build: true)
        trace_class_for_mode.new(**trace_options)
      end

      # @param new_analyzer [Class<GraphQL::Analysis::Analyzer>] An analyzer to run on queries to this schema
      # @see GraphQL::Analysis the analysis system
      def query_analyzer(new_analyzer)
        own_query_analyzers << new_analyzer
      end

      def query_analyzers
        find_inherited_value(:query_analyzers, EMPTY_ARRAY) + own_query_analyzers
      end

      # @param new_analyzer [Class<GraphQL::Analysis::Analyzer>] An analyzer to run on multiplexes to this schema
      # @see GraphQL::Analysis the analysis system
      def multiplex_analyzer(new_analyzer)
        own_multiplex_analyzers << new_analyzer
      end

      def multiplex_analyzers
        find_inherited_value(:multiplex_analyzers, EMPTY_ARRAY) + own_multiplex_analyzers
      end

      def sanitized_printer(new_sanitized_printer = nil)
        if new_sanitized_printer
          @own_sanitized_printer = new_sanitized_printer
        else
          @own_sanitized_printer || GraphQL::Language::SanitizedPrinter
        end
      end

      # Execute a query on itself.
      # @see {Query#initialize} for arguments.
      # @return [GraphQL::Query::Result] query result, ready to be serialized as JSON
      def execute(query_str = nil, **kwargs)
        if query_str
          kwargs[:query] = query_str
        end
        # Some of the query context _should_ be passed to the multiplex, too
        multiplex_context = if (ctx = kwargs[:context])
          {
            backtrace: ctx[:backtrace],
            tracers: ctx[:tracers],
            trace: ctx[:trace],
            dataloader: ctx[:dataloader],
            trace_mode: ctx[:trace_mode],
          }
        else
          {}
        end
        # Since we're running one query, don't run a multiplex-level complexity analyzer
        all_results = multiplex([kwargs], max_complexity: nil, context: multiplex_context)
        all_results[0]
      end

      # Execute several queries on itself, concurrently.
      #
      # @example Run several queries at once
      #   context = { ... }
      #   queries = [
      #     { query: params[:query_1], variables: params[:variables_1], context: context },
      #     { query: params[:query_2], variables: params[:variables_2], context: context },
      #   ]
      #   results = MySchema.multiplex(queries)
      #   render json: {
      #     result_1: results[0],
      #     result_2: results[1],
      #   }
      #
      # @see {Query#initialize} for query keyword arguments
      # @see {Execution::Multiplex#run_all} for multiplex keyword arguments
      # @param queries [Array<Hash>] Keyword arguments for each query
      # @param context [Hash] Multiplex-level context
      # @return [Array<GraphQL::Query::Result>] One result for each query in the input
      def multiplex(queries, **kwargs)
        GraphQL::Execution::Interpreter.run_all(self, queries, **kwargs)
      end

      def instrumenters
        inherited_instrumenters = find_inherited_value(:instrumenters) || Hash.new { |h,k| h[k] = [] }
        inherited_instrumenters.merge(own_instrumenters) do |_step, inherited, own|
          inherited + own
        end
      end

      # @api private
      def add_subscription_extension_if_necessary
        # TODO: when there's a proper API for extending root types, migrat this to use it.
        if !defined?(@subscription_extension_added) && @subscription_object.is_a?(Class) && self.subscriptions
          @subscription_extension_added = true
          subscription.all_field_definitions.each do |field|
            if !field.extensions.any? { |ext| ext.is_a?(Subscriptions::DefaultSubscriptionResolveExtension) }
              field.extension(Subscriptions::DefaultSubscriptionResolveExtension)
            end
          end
        end
      end

      # Called when execution encounters a `SystemStackError`. By default, it adds a client-facing error to the response.
      # You could modify this method to report this error to your bug tracker.
      # @param query [GraphQL::Query]
      # @param err [SystemStackError]
      # @return [void]
      def query_stack_error(query, err)
        query.context.errors.push(GraphQL::ExecutionError.new("This query is too large to execute."))
      end

      # Call the given block at the right time, either:
      # - Right away, if `value` is not registered with `lazy_resolve`
      # - After resolving `value`, if it's registered with `lazy_resolve` (eg, `Promise`)
      # @api private
      def after_lazy(value, &block)
        if lazy?(value)
          GraphQL::Execution::Lazy.new do
            result = sync_lazy(value)
            # The returned result might also be lazy, so check it, too
            after_lazy(result, &block)
          end
        else
          yield(value) if block_given?
        end
      end

      # Override this method to handle lazy objects in a custom way.
      # @param value [Object] an instance of a class registered with {.lazy_resolve}
      # @return [Object] A GraphQL-ready (non-lazy) object
      # @api private
      def sync_lazy(value)
        lazy_method = lazy_method_name(value)
        if lazy_method
          synced_value = value.public_send(lazy_method)
          sync_lazy(synced_value)
        else
          value
        end
      end

      # @return [Symbol, nil] The method name to lazily resolve `obj`, or nil if `obj`'s class wasn't registered with {#lazy_resolve}.
      def lazy_method_name(obj)
        lazy_methods.get(obj)
      end

      # @return [Boolean] True if this object should be lazily resolved
      def lazy?(obj)
        !!lazy_method_name(obj)
      end

      # Return a lazy if any of `maybe_lazies` are lazy,
      # otherwise, call the block eagerly and return the result.
      # @param maybe_lazies [Array]
      # @api private
      def after_any_lazies(maybe_lazies)
        if maybe_lazies.any? { |l| lazy?(l) }
          GraphQL::Execution::Lazy.all(maybe_lazies).then do |result|
            yield result
          end
        else
          yield maybe_lazies
        end
      end

      # Returns `DidYouMean` if it's defined.
      # Override this to return `nil` if you don't want to use `DidYouMean`
      def did_you_mean(new_dym = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_dym)
          if defined?(@did_you_mean)
            @did_you_mean
          else
            find_inherited_value(:did_you_mean, defined?(DidYouMean) ? DidYouMean : nil)
          end
        else
          @did_you_mean = new_dym
        end
      end

      private

      def add_trace_options_for(mode, new_options)
        if mode == :default
          own_trace_modes.each do |mode_name, t_class|
            if t_class <= DefaultTraceClass
              t_opts = trace_options_for(mode_name)
              t_opts.merge!(new_options)
            end
          end
        else
          t_opts = trace_options_for(mode)
          t_opts.merge!(new_options)
        end
        nil
      end

      # @param t [Module, Array<Module>]
      # @return [void]
      def add_type_and_traverse(t, root:)
        if root
          @root_types ||= []
          @root_types << t
        end
        new_types = Array(t)
        addition = Schema::Addition.new(schema: self, own_types: own_types, new_types: new_types)
        addition.types.each do |name, types_entry| # rubocop:disable Development/ContextIsPassedCop -- build-time, not query-time
          if (prev_entry = own_types[name])
            prev_entries = case prev_entry
            when Array
              prev_entry
            when Module
              own_types[name] = [prev_entry]
            else
              raise "Invariant: unexpected prev_entry at #{name.inspect} when adding #{t.inspect}"
            end

            case types_entry
            when Array
              prev_entries.concat(types_entry)
              prev_entries.uniq! # in case any are being re-visited
            when Module
              if !prev_entries.include?(types_entry)
                prev_entries << types_entry
              end
            else
              raise "Invariant: unexpected types_entry at #{name} when adding #{t.inspect}"
            end
          else
            if types_entry.is_a?(Array)
              types_entry.uniq!
            end
            own_types[name] = types_entry
          end
        end

        own_possible_types.merge!(addition.possible_types) { |key, old_val, new_val| old_val + new_val }
        own_union_memberships.merge!(addition.union_memberships)

        addition.references.each { |thing, pointers|
          prev_refs = own_references_to[thing] || []
          own_references_to[thing] = prev_refs | pointers.to_a
        }

        addition.directives.each { |dir_class| own_directives[dir_class.graphql_name] = dir_class }

        addition.arguments_with_default_values.each do |arg|
          arg.validate_default_value
        end
      end

      def lazy_methods
        if !defined?(@lazy_methods)
          if inherited_map = find_inherited_value(:lazy_methods)
            # this isn't _completely_ inherited :S (Things added after `dup` won't work)
            @lazy_methods = inherited_map.dup
          else
            @lazy_methods = GraphQL::Execution::Lazy::LazyMethodMap.new
            @lazy_methods.set(GraphQL::Execution::Lazy, :value)
            @lazy_methods.set(GraphQL::Dataloader::Request, :load_with_deprecation_warning)
          end
        end
        @lazy_methods
      end

      def own_types
        @own_types ||= {}
      end

      def own_references_to
        @own_references_to ||= {}.compare_by_identity
      end

      def non_introspection_types
        find_inherited_value(:non_introspection_types, EMPTY_HASH).merge(own_types)
      end

      def own_plugins
        @own_plugins ||= []
      end

      def own_orphan_types
        @own_orphan_types ||= []
      end

      def own_possible_types
        @own_possible_types ||= {}.compare_by_identity
      end

      def own_union_memberships
        @own_union_memberships ||= {}
      end

      def own_directives
        @own_directives ||= {}
      end

      def own_instrumenters
        @own_instrumenters ||= Hash.new { |h,k| h[k] = [] }
      end

      def own_tracers
        @own_tracers ||= []
      end

      def own_query_analyzers
        @defined_query_analyzers ||= []
      end

      def own_multiplex_analyzers
        @own_multiplex_analyzers ||= []
      end

      # This is overridden in subclasses to check the inheritance chain
      def get_references_to(type_defn)
        own_references_to[type_defn]
      end
    end

    module SubclassGetReferencesTo
      def get_references_to(type_defn)
        own_refs = own_references_to[type_defn]
        inherited_refs = superclass.references_to(type_defn)
        if inherited_refs&.any?
          if own_refs&.any?
            own_refs + inherited_refs
          else
            inherited_refs
          end
        else
          own_refs
        end
      end
    end

    # Install these here so that subclasses will also install it.
    self.connections = GraphQL::Pagination::Connections.new(schema: self)

    # @api private
    module DefaultTraceClass
    end
  end
end

require "graphql/schema/loader"
require "graphql/schema/printer"
