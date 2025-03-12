# frozen_string_literal: true

module GraphQL
  class Schema
    class Addition
      attr_reader :directives, :possible_types, :types, :union_memberships, :references, :arguments_with_default_values

      def initialize(schema:, own_types:, new_types:)
        @schema = schema
        @own_types = own_types
        @directives = Set.new
        @possible_types = {}
        @types = {}
        @union_memberships = {}
        @references = Hash.new { |h, k| h[k] = Set.new }
        @arguments_with_default_values = []
        add_type_and_traverse(new_types)
      end

      private

      def references_to(thing, from:)
        @references[thing].add(from)
      end

      def get_type(name)
        local_type = @types[name]
        # This isn't really sophisticated, but
        # I think it's good enough to support the current usage of LateBoundTypes
        if local_type.is_a?(Array)
          local_type = local_type.first
        end
        local_type || @schema.get_type(name)
      end

      # Lookup using `own_types` here because it's ok to override
      # inherited types by name
      def get_local_type(name)
        @types[name] || @own_types[name]
      end

      def add_directives_from(owner)
        if !(dir_instances = owner.directives).empty?
          dirs = dir_instances.map(&:class)
          @directives.merge(dirs)
          add_type_and_traverse(dirs)
        end
      end

      def add_type_and_traverse(new_types)
        late_types = []
        path = []
        new_types.each do |t|
          path.push(t.graphql_name)
          add_type(t, owner: nil, late_types: late_types, path: path)
          path.pop
        end
        missed_late_types = 0
        while (late_type_vals = late_types.shift)
          type_owner, lt = late_type_vals
          if lt.is_a?(String)
            type = Member::BuildType.constantize(lt)
            # Reset the counter, since we might succeed next go-round
            missed_late_types = 0
            update_type_owner(type_owner, type)
            add_type(type, owner: type_owner, late_types: late_types, path: [type.graphql_name])
          elsif lt.is_a?(LateBoundType)
            if (type = get_type(lt.name))
              # Reset the counter, since we might succeed next go-round
              missed_late_types = 0
              update_type_owner(type_owner, type)
              add_type(type, owner: type_owner, late_types: late_types, path: [type.graphql_name])
            else
              missed_late_types += 1
              # Add it back to the list, maybe we'll be able to resolve it later.
              late_types << [type_owner, lt]
              if missed_late_types == late_types.size
                # We've looked at all of them and haven't resolved one.
                raise UnresolvedLateBoundTypeError.new(type: lt)
              else
                # Try the next one
              end
            end
          else
            raise ArgumentError, "Unexpected late type: #{lt.inspect}"
          end
        end
        nil
      end

      def update_type_owner(owner, type)
        case owner
        when Module
          if owner.kind.union?
            # It's a union with possible_types
            # Replace the item by class name
            owner.assign_type_membership_object_type(type)
            @possible_types[owner] = owner.possible_types
          elsif type.kind.interface? && (owner.kind.object? || owner.kind.interface?)
            new_interfaces = []
            owner.interfaces.each do |int_t|
              if int_t.is_a?(String) && int_t == type.graphql_name
                new_interfaces << type
              elsif int_t.is_a?(LateBoundType) && int_t.graphql_name == type.graphql_name
                new_interfaces << type
              else
                # Don't re-add proper interface definitions,
                # they were probably already added, maybe with options.
              end
            end
            owner.implements(*new_interfaces)
            new_interfaces.each do |int|
              pt = @possible_types[int] ||= []
              if !pt.include?(owner) && owner.is_a?(Class)
                pt << owner
              end
              int.interfaces.each do |indirect_int|
                if indirect_int.is_a?(LateBoundType) && (indirect_int_type = get_type(indirect_int.graphql_name))
                  update_type_owner(owner, indirect_int_type)
                end
              end
            end
          end
        when nil
          # It's a root type
          @types[type.graphql_name] = type
        when GraphQL::Schema::Field, GraphQL::Schema::Argument
          orig_type = owner.type
          unwrapped_t = type
          # Apply list/non-null wrapper as needed
          if orig_type.respond_to?(:of_type)
            transforms = []
            while (orig_type.respond_to?(:of_type))
              if orig_type.kind.non_null?
                transforms << :to_non_null_type
              elsif orig_type.kind.list?
                transforms << :to_list_type
              else
                raise "Invariant: :of_type isn't non-null or list"
              end
              orig_type = orig_type.of_type
            end
            transforms.reverse_each { |t| type = type.public_send(t) }
          end
          owner.type = type
          references_to(unwrapped_t, from: owner)
        else
          raise "Unexpected update: #{owner.inspect} #{type.inspect}"
        end
      end

      def add_type(type, owner:, late_types:, path:)
        if type.is_a?(String) || type.is_a?(GraphQL::Schema::LateBoundType)
          late_types << [owner, type]
          return
        end

        if owner.is_a?(Class) && owner < GraphQL::Schema::Union
          um = @union_memberships[type.graphql_name] ||= []
          um << owner
        end

        if (prev_type = get_local_type(type.graphql_name)) && (prev_type == type || (prev_type.is_a?(Array) && prev_type.include?(type)))
          # No need to re-visit
        elsif type.is_a?(Class) && type < GraphQL::Schema::Directive
          @directives << type
          type.all_argument_definitions.each do |arg|
            arg_type = arg.type.unwrap
            if !arg_type.is_a?(GraphQL::Schema::LateBoundType)
              references_to(arg_type, from: arg)
            end
            path.push(arg.graphql_name)
            add_type(arg_type, owner: arg, late_types: late_types, path: path)
            path.pop
            if arg.default_value?
              @arguments_with_default_values << arg
            end
          end
        else
          prev_type = @types[type.graphql_name]
          if prev_type.nil?
            @types[type.graphql_name] = type
          elsif prev_type.is_a?(Array)
            prev_type << type
          else
            @types[type.graphql_name] = [prev_type, type]
          end

          add_directives_from(type)
          if type.kind.fields?
            type.all_field_definitions.each do |field|
              field.ensure_loaded
              name = field.graphql_name
              field_type = field.type.unwrap
              if !field_type.is_a?(GraphQL::Schema::LateBoundType)
                references_to(field_type, from: field)
              end
              path.push(name)
              add_type(field_type, owner: field, late_types: late_types, path: path)
              add_directives_from(field)
              field.all_argument_definitions.each do |arg|
                add_directives_from(arg)
                arg_type = arg.type.unwrap
                if !arg_type.is_a?(GraphQL::Schema::LateBoundType)
                  references_to(arg_type, from: arg)
                end
                path.push(arg.graphql_name)
                add_type(arg_type, owner: arg, late_types: late_types, path: path)
                path.pop
                if arg.default_value?
                  @arguments_with_default_values << arg
                end
              end
              path.pop
            end
          end
          if type.kind.input_object?
            type.all_argument_definitions.each do |arg|
              add_directives_from(arg)
              arg_type = arg.type.unwrap
              if !arg_type.is_a?(GraphQL::Schema::LateBoundType)
                references_to(arg_type, from: arg)
              end
              path.push(arg.graphql_name)
              add_type(arg_type, owner: arg, late_types: late_types, path: path)
              path.pop
              if arg.default_value?
                @arguments_with_default_values << arg
              end
            end
          end
          if type.kind.union?
            @possible_types[type] = type.all_possible_types
            path.push("possible_types")
            type.all_possible_types.each do |t|
              add_type(t, owner: type, late_types: late_types, path: path)
            end
            path.pop
          end
          if type.kind.interface?
            path.push("orphan_types")
            type.orphan_types.each do |t|
              add_type(t, owner: type, late_types: late_types, path: path)
            end
            path.pop
          end
          if type.kind.object?
            possible_types_for_this_name = @possible_types[type] ||= []
            possible_types_for_this_name << type
          end

          if type.kind.object? || type.kind.interface?
            path.push("implements")
            type.interface_type_memberships.each do |interface_type_membership|
              case interface_type_membership
              when Schema::TypeMembership
                interface_type = interface_type_membership.abstract_type
                # We can get these now; we'll have to get late-bound types later
                if interface_type.is_a?(Module) && type.is_a?(Class)
                  implementers = @possible_types[interface_type] ||= []
                  implementers << type
                end
              when String, Schema::LateBoundType
                interface_type = interface_type_membership
              else
                raise ArgumentError, "Invariant: unexpected type membership for #{type.graphql_name}: #{interface_type_membership.class} (#{interface_type_membership.inspect})"
              end
              add_type(interface_type, owner: type, late_types: late_types, path: path)
            end
            path.pop
          end

          if type.kind.enum?
            type.all_enum_value_definitions.each do |value_definition|
              add_directives_from(value_definition)
            end
          end
        end
      end
    end
  end
end
