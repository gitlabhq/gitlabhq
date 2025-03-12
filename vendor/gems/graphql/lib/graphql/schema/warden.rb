# frozen_string_literal: true

require 'set'

module GraphQL
  class Schema
    # Restrict access to a {GraphQL::Schema} with a user-defined `visible?` implementations.
    #
    # When validating and executing a query, all access to schema members
    # should go through a warden. If you access the schema directly,
    # you may show a client something that it shouldn't be allowed to see.
    #
    # @api private
    class Warden
      def self.from_context(context)
        context.warden || PassThruWarden
      rescue NoMethodError
        # this might be a hash which won't respond to #warden
        PassThruWarden
      end

      def self.types_from_context(context)
        context.types || PassThruWarden
      rescue NoMethodError
        # this might be a hash which won't respond to #warden
        PassThruWarden
      end

      def self.use(schema)
        # no-op
      end

      # @param visibility_method [Symbol] a Warden method to call for this entry
      # @param entry [Object, Array<Object>] One or more definitions for a given name in a GraphQL Schema
      # @param context [GraphQL::Query::Context]
      # @param warden [Warden]
      # @return [Object] `entry` or one of `entry`'s items if exactly one of them is visible for this context
      # @return [nil] If neither `entry` nor any of `entry`'s items are visible for this context
      def self.visible_entry?(visibility_method, entry, context, warden = Warden.from_context(context))
        if entry.is_a?(Array)
          visible_item = nil
          entry.each do |item|
            if warden.public_send(visibility_method, item, context)
              if visible_item.nil?
                visible_item = item
              else
                raise DuplicateNamesError.new(
                  duplicated_name: item.path, duplicated_definition_1: visible_item.inspect, duplicated_definition_2: item.inspect
                )
              end
            end
          end
          visible_item
        elsif warden.public_send(visibility_method, entry, context)
          entry
        else
          nil
        end
      end

      # This is used when a caller provides a Hash for context.
      # We want to call the schema's hooks, but we don't have a full-blown warden.
      # The `context` arguments to these methods exist purely to simplify the code that
      # calls methods on this object, so it will have everything it needs.
      class PassThruWarden
        class << self
          def visible_field?(field, ctx); field.visible?(ctx); end
          def visible_argument?(arg, ctx); arg.visible?(ctx); end
          def visible_type?(type, ctx); type.visible?(ctx); end
          def visible_enum_value?(ev, ctx); ev.visible?(ctx); end
          def visible_type_membership?(tm, ctx); tm.visible?(ctx); end
          def interface_type_memberships(obj_t, ctx); obj_t.interface_type_memberships; end
          def arguments(owner, ctx); owner.arguments(ctx); end
          def loadable?(type, ctx); type.visible?(ctx); end
          def loadable_possible_types(type, ctx); type.possible_types(ctx); end
          def visibility_profile
            @visibility_profile ||= Warden::VisibilityProfile.new(self)
          end
        end
      end

      class NullWarden
        def initialize(_filter = nil, context:, schema:)
          @schema = schema
          @visibility_profile = Warden::VisibilityProfile.new(self)
        end

        # No-op, but for compatibility:
        attr_writer :skip_warning

        attr_reader :visibility_profile

        def visible_field?(field_defn, _ctx = nil, owner = nil); true; end
        def visible_argument?(arg_defn, _ctx = nil); true; end
        def visible_type?(type_defn, _ctx = nil); true; end
        def visible_enum_value?(enum_value, _ctx = nil); enum_value.visible?(Query::NullContext.instance); end
        def visible_type_membership?(type_membership, _ctx = nil); true; end
        def interface_type_memberships(obj_type, _ctx = nil); obj_type.interface_type_memberships; end
        def get_type(type_name); @schema.get_type(type_name, Query::NullContext.instance, false); end # rubocop:disable Development/ContextIsPassedCop
        def arguments(argument_owner, ctx = nil); argument_owner.all_argument_definitions; end
        def enum_values(enum_defn); enum_defn.enum_values(Query::NullContext.instance); end # rubocop:disable Development/ContextIsPassedCop
        def get_argument(parent_type, argument_name); parent_type.get_argument(argument_name); end # rubocop:disable Development/ContextIsPassedCop
        def types; @schema.types; end # rubocop:disable Development/ContextIsPassedCop
        def root_type_for_operation(op_name); @schema.root_type_for_operation(op_name); end
        def directives; @schema.directives.values; end
        def fields(type_defn); type_defn.all_field_definitions; end # rubocop:disable Development/ContextIsPassedCop
        def get_field(parent_type, field_name); @schema.get_field(parent_type, field_name); end
        def reachable_type?(type_name); true; end
        def loadable?(type, _ctx); true; end
        def loadable_possible_types(union_type, _ctx); union_type.possible_types; end
        def reachable_types; @schema.types.values; end # rubocop:disable Development/ContextIsPassedCop
        def possible_types(type_defn); @schema.possible_types(type_defn, Query::NullContext.instance, false); end
        def interfaces(obj_type); obj_type.interfaces; end
      end

      def visibility_profile
        @visibility_profile ||= VisibilityProfile.new(self)
      end

      class VisibilityProfile
        def initialize(warden)
          @warden = warden
        end

        def directives
          @warden.directives
        end

        def directive_exists?(dir_name)
          @warden.directives.any? { |d| d.graphql_name == dir_name }
        end

        def type(name)
          @warden.get_type(name)
        end

        def field(owner, field_name)
          @warden.get_field(owner, field_name)
        end

        def argument(owner, arg_name)
          @warden.get_argument(owner, arg_name)
        end

        def query_root
          @warden.root_type_for_operation("query")
        end

        def mutation_root
          @warden.root_type_for_operation("mutation")
        end

        def subscription_root
          @warden.root_type_for_operation("subscription")
        end

        def arguments(owner)
          @warden.arguments(owner)
        end

        def fields(owner)
          @warden.fields(owner)
        end

        def possible_types(type)
          @warden.possible_types(type)
        end

        def enum_values(enum_type)
          @warden.enum_values(enum_type)
        end

        def all_types
          @warden.reachable_types
        end

        def interfaces(obj_type)
          @warden.interfaces(obj_type)
        end

        def loadable?(t, ctx) # TODO remove ctx here?
          @warden.loadable?(t, ctx)
        end

        def loadable_possible_types(t, ctx)
          @warden.loadable_possible_types(t, ctx)
        end

        def reachable_type?(type_name)
          !!@warden.reachable_type?(type_name)
        end

        def visible_enum_value?(enum_value, ctx = nil)
          @warden.visible_enum_value?(enum_value, ctx)
        end
      end

      # @param context [GraphQL::Query::Context]
      # @param schema [GraphQL::Schema]
      def initialize(context:, schema:)
        @schema = schema
        # Cache these to avoid repeated hits to the inheritance chain when one isn't present
        @query = @schema.query
        @mutation = @schema.mutation
        @subscription = @schema.subscription
        @context = context
        @visibility_cache = read_through { |m| check_visible(schema, m) }
        # Initialize all ivars to improve object shape consistency:
        @types = @visible_types = @reachable_types = @visible_parent_fields =
          @visible_possible_types = @visible_fields = @visible_arguments = @visible_enum_arrays =
          @visible_enum_values = @visible_interfaces = @type_visibility = @type_memberships =
          @visible_and_reachable_type = @unions = @unfiltered_interfaces =
          @reachable_type_set = @visibility_profile = @loadable_possible_types =
            nil
        @skip_warning = schema.plugins.any? { |(plugin, _opts)| plugin == GraphQL::Schema::Warden }
      end

      attr_writer :skip_warning

      # @return [Hash<String, GraphQL::BaseType>] Visible types in the schema
      def types
        @types ||= begin
          vis_types = {}
          @schema.types(@context).each do |n, t|
            if visible_and_reachable_type?(t)
              vis_types[n] = t
            end
          end
          vis_types
        end
      end

      # @return [Boolean] True if this type is used for `loads:` but not in the schema otherwise and not _explicitly_ hidden.
      def loadable?(type, _ctx)
        !reachable_type_set.include?(type) && visible_type?(type)
      end

      def loadable_possible_types(union_type, _ctx)
        @loadable_possible_types ||= read_through do |t|
          t.possible_types # unfiltered
        end
        @loadable_possible_types[union_type]
      end

      # @return [GraphQL::BaseType, nil] The type named `type_name`, if it exists (else `nil`)
      def get_type(type_name)
        @visible_types ||= read_through do |name|
          type_defn = @schema.get_type(name, @context, false)
          if type_defn && visible_and_reachable_type?(type_defn)
            type_defn
          else
            nil
          end
        end

        @visible_types[type_name]
      end

      # @return [Array<GraphQL::BaseType>] Visible and reachable types in the schema
      def reachable_types
        @reachable_types ||= reachable_type_set.to_a
      end

      # @return Boolean True if the type is visible and reachable in the schema
      def reachable_type?(type_name)
        type = get_type(type_name) # rubocop:disable Development/ContextIsPassedCop -- `self` is query-aware
        type && reachable_type_set.include?(type)
      end

      # @return [GraphQL::Field, nil] The field named `field_name` on `parent_type`, if it exists
      def get_field(parent_type, field_name)
        @visible_parent_fields ||= read_through do |type|
          read_through do |f_name|
            field_defn = @schema.get_field(type, f_name, @context)
            if field_defn && visible_field?(field_defn, nil, type)
              field_defn
            else
              nil
            end
          end
        end

        @visible_parent_fields[parent_type][field_name]
      end

      # @return [GraphQL::Argument, nil] The argument named `argument_name` on `parent_type`, if it exists and is visible
      def get_argument(parent_type, argument_name)
        argument = parent_type.get_argument(argument_name, @context)
        return argument if argument && visible_argument?(argument, @context)
      end

      # @return [Array<GraphQL::BaseType>] The types which may be member of `type_defn`
      def possible_types(type_defn)
        @visible_possible_types ||= read_through { |type_defn|
          pt = @schema.possible_types(type_defn, @context, false)
          pt.select { |t| visible_and_reachable_type?(t) }
        }
        @visible_possible_types[type_defn]
      end

      # @param type_defn [GraphQL::ObjectType, GraphQL::InterfaceType]
      # @return [Array<GraphQL::Field>] Fields on `type_defn`
      def fields(type_defn)
        @visible_fields ||= read_through { |t| @schema.get_fields(t, @context).values }
        @visible_fields[type_defn]
      end

      # @param argument_owner [GraphQL::Field, GraphQL::InputObjectType]
      # @return [Array<GraphQL::Argument>] Visible arguments on `argument_owner`
      def arguments(argument_owner, ctx = nil)
        @visible_arguments ||= read_through { |o|
          args = o.arguments(@context)
          if !args.empty?
            args = args.values
            args.select! { |a| visible_argument?(a, @context) }
            args
          else
            EmptyObjects::EMPTY_ARRAY
          end
        }
        @visible_arguments[argument_owner]
      end

      # @return [Array<GraphQL::EnumType::EnumValue>] Visible members of `enum_defn`
      def enum_values(enum_defn)
        @visible_enum_arrays ||= read_through { |e|
          values = e.enum_values(@context)
          if values.size == 0
            raise GraphQL::Schema::Enum::MissingValuesError.new(e)
          end
          values
        }
        @visible_enum_arrays[enum_defn]
      end

      def visible_enum_value?(enum_value, _ctx = nil)
        @visible_enum_values ||= read_through { |ev| visible?(ev) }
        @visible_enum_values[enum_value]
      end

      # @return [Array<GraphQL::InterfaceType>] Visible interfaces implemented by `obj_type`
      def interfaces(obj_type)
        @visible_interfaces ||= read_through { |t|
          ints = t.interfaces(@context)
          if !ints.empty?
            ints.select! { |i| visible_type?(i) }
          end
          ints
        }
        @visible_interfaces[obj_type]
      end

      def directives
        @schema.directives.each_value.select { |d| visible?(d) }
      end

      def root_type_for_operation(op_name)
        root_type = @schema.root_type_for_operation(op_name)
        if root_type && visible?(root_type)
          root_type
        else
          nil
        end
      end

      # @param owner [Class, Module] If provided, confirm that field has the given owner.
      def visible_field?(field_defn, _ctx = nil, owner = field_defn.owner)
        # This field is visible in its own right
        visible?(field_defn) &&
          # This field's return type is visible
          visible_and_reachable_type?(field_defn.type.unwrap) &&
          # This field is either defined on this object type,
          # or the interface it's inherited from is also visible
          ((field_defn.respond_to?(:owner) && field_defn.owner == owner) || field_on_visible_interface?(field_defn, owner))
      end

      def visible_argument?(arg_defn, _ctx = nil)
        visible?(arg_defn) && visible_and_reachable_type?(arg_defn.type.unwrap)
      end

      def visible_type?(type_defn, _ctx = nil)
        @type_visibility ||= read_through { |type_defn| visible?(type_defn) }
        @type_visibility[type_defn]
      end

      def visible_type_membership?(type_membership, _ctx = nil)
        visible?(type_membership)
      end

      def interface_type_memberships(obj_type, _ctx = nil)
        @type_memberships ||= read_through do |obj_t|
          obj_t.interface_type_memberships
        end
        @type_memberships[obj_type]
      end

      private

      def visible_and_reachable_type?(type_defn)
        @visible_and_reachable_type ||= read_through do |type_defn|
          next false unless visible_type?(type_defn)
          next true if root_type?(type_defn) || type_defn.introspection?

          if type_defn.kind.union?
            !possible_types(type_defn).empty? && (referenced?(type_defn) || orphan_type?(type_defn))
          elsif type_defn.kind.interface?
            if !possible_types(type_defn).empty?
              true
            else
              if @context.respond_to?(:logger) && (logger = @context.logger)
                logger.debug { "Interface `#{type_defn.graphql_name}` hidden because it has no visible implementers" }
              end
              false
            end
          else
            if referenced?(type_defn)
              true
            elsif type_defn.kind.object?
              # Show this object if it belongs to ...
              interfaces(type_defn).any? { |t| referenced?(t) } ||  # an interface which is referenced in the schema
                union_memberships(type_defn).any? { |t| referenced?(t) || orphan_type?(t) } # or a union which is referenced or added via orphan_types
            else
              false
            end
          end
        end

        @visible_and_reachable_type[type_defn]
      end

      def union_memberships(obj_type)
        @unions ||= read_through { |obj_type| @schema.union_memberships(obj_type).select { |u| visible?(u) } }
        @unions[obj_type]
      end

      # We need this to tell whether a field was inherited by an interface
      # even when that interface is hidden from `#interfaces`
      def unfiltered_interfaces(type_defn)
        @unfiltered_interfaces ||= read_through(&:interfaces)
        @unfiltered_interfaces[type_defn]
      end

      # If this field was inherited from an interface, and the field on that interface is _hidden_,
      # then treat this inherited field as hidden.
      # (If it _wasn't_ inherited, then don't hide it for this reason.)
      def field_on_visible_interface?(field_defn, type_defn)
        if type_defn.kind.object?
          any_interface_has_field = false
          any_interface_has_visible_field = false
          ints = unfiltered_interfaces(type_defn)
          ints.each do |interface_type|
            if (iface_field_defn = interface_type.get_field(field_defn.graphql_name, @context))
              any_interface_has_field = true

              if interfaces(type_defn).include?(interface_type) && visible_field?(iface_field_defn, nil, interface_type)
                any_interface_has_visible_field = true
              end
            end
          end

          if any_interface_has_field
            any_interface_has_visible_field
          else
            # it's the object's own field
            true
          end
        else
          true
        end
      end

      def root_type?(type_defn)
        @query == type_defn ||
          @mutation == type_defn ||
          @subscription == type_defn
      end

      def referenced?(type_defn)
        members = @schema.references_to(type_defn)
        members.any? { |m| visible?(m) }
      end

      def orphan_type?(type_defn)
        @schema.orphan_types.include?(type_defn)
      end

      def visible?(member)
        @visibility_cache[member]
      end

      def read_through
        Hash.new { |h, k| h[k] = yield(k) }.compare_by_identity
      end

      def check_visible(schema, member)
        if schema.visible?(member, @context)
          true
        elsif @skip_warning
          false
        else
          member_s = member.respond_to?(:path) ? member.path : member.inspect
          member_type = case member
          when Module
            if member.respond_to?(:kind)
              member.kind.name.downcase
            else
              ""
            end
          when GraphQL::Schema::Field
            "field"
          when GraphQL::Schema::EnumValue
            "enum value"
          when GraphQL::Schema::Argument
            "argument"
          else
            ""
          end

          schema_s = schema.name ? "#{schema.name}'s" : ""
          schema_name = schema.name ? "#{schema.name}" : "your schema"
          warn(ADD_WARDEN_WARNING % { schema_s: schema_s, schema_name: schema_name, member: member_s, member_type: member_type })
          @skip_warning = true # only warn once per query
          # If there's no schema name, add the backtrace for additional context:
          if schema_s == ""
            puts caller.map { |l| "    #{l}"}
          end
          false
        end
      end

      ADD_WARDEN_WARNING = <<~WARNING
DEPRECATION: %{schema_s} "%{member}" %{member_type} returned `false` for `.visible?` but `GraphQL::Schema::Visibility` isn't configured yet.

  Address this warning by adding:

      use GraphQL::Schema::Visibility

  to the definition for %{schema_name}. (Future GraphQL-Ruby versions won't check `.visible?` methods by default.)

  Alternatively, for legacy behavior, add:

      use GraphQL::Schema::Warden # legacy visibility behavior

  For more information see: https://graphql-ruby.org/authorization/visibility.html
      WARNING

      def reachable_type_set
        return @reachable_type_set if @reachable_type_set

        @reachable_type_set = Set.new
        rt_hash = {}

        unvisited_types = []
        ['query', 'mutation', 'subscription'].each do |op_name|
          root_type = root_type_for_operation(op_name)
          unvisited_types << root_type if root_type
        end
        unvisited_types.concat(@schema.introspection_system.types.values)

        directives.each do |dir_class|
          arguments(dir_class).each do |arg_defn|
            arg_t = arg_defn.type.unwrap
            if get_type(arg_t.graphql_name) # rubocop:disable Development/ContextIsPassedCop -- `self` is query-aware
              unvisited_types << arg_t
            end
          end
        end

        @schema.orphan_types.each do |orphan_type|
          if get_type(orphan_type.graphql_name) == orphan_type # rubocop:disable Development/ContextIsPassedCop -- `self` is query-aware
            unvisited_types << orphan_type
          end
        end

        included_interface_possible_types_set = Set.new

        until unvisited_types.empty?
          type = unvisited_types.pop
          visit_type(type, unvisited_types, @reachable_type_set, rt_hash, included_interface_possible_types_set, include_interface_possible_types: false)
        end

        @reachable_type_set
      end

      def visit_type(type, unvisited_types, visited_type_set, type_by_name_hash, included_interface_possible_types_set, include_interface_possible_types:)
        if visited_type_set.add?(type) || (include_interface_possible_types && type.kind.interface? && included_interface_possible_types_set.add?(type))
          type_by_name = type_by_name_hash[type.graphql_name] ||= type
          if type_by_name != type
            name_1, name_2 = [type.inspect, type_by_name.inspect].sort
            raise DuplicateNamesError.new(
              duplicated_name: type.graphql_name, duplicated_definition_1: name_1, duplicated_definition_2: name_2
            )
          end
          if type.kind.input_object?
            # recurse into visible arguments
            arguments(type).each do |argument|
              argument_type = argument.type.unwrap
              unvisited_types << argument_type
            end
          elsif type.kind.union?
            # recurse into visible possible types
            possible_types(type).each do |possible_type|
              unvisited_types << possible_type
            end
          elsif type.kind.fields?
            if type.kind.object?
              # recurse into visible implemented interfaces
              interfaces(type).each do |interface|
                unvisited_types << interface
              end
            elsif include_interface_possible_types
              possible_types(type).each do |pt|
                unvisited_types << pt
              end
            end
            # Don't visit interface possible types -- it's not enough to justify visibility

            # recurse into visible fields
            fields(type).each do |field|
              field_type = field.type.unwrap
              # In this case, if it's an interface, we want to include
              visit_type(field_type, unvisited_types, visited_type_set, type_by_name_hash, included_interface_possible_types_set, include_interface_possible_types: true)
              # recurse into visible arguments
              arguments(field).each do |argument|
                argument_type = argument.type.unwrap
                unvisited_types << argument_type
              end
            end
          end
        end
      end
    end
  end
end
