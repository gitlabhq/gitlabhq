# frozen_string_literal: true
module GraphQL
  class Schema
    class Visibility
      class Visit
        def initialize(schema, &visit_block)
          @schema = schema
          @late_bound_types = nil
          @unvisited_types = nil
          # These accumulate between calls to prevent re-visiting the same types
          @visited_types = Set.new.compare_by_identity
          @visited_directives = Set.new.compare_by_identity
          @visit_block = visit_block
        end

        def entry_point_types
          ept = [
            @schema.query,
            @schema.mutation,
            @schema.subscription,
            *@schema.introspection_system.types.values,
            *@schema.orphan_types,
          ]
          ept.compact!
          ept
        end

        def entry_point_directives
          @schema.directives.values
        end

        def visit_each(types: entry_point_types, directives: entry_point_directives)
          @unvisited_types && raise("Can't re-enter `visit_each` on this Visit (another visit is already in progress)")
          @unvisited_types = types
          @late_bound_types = []
          directives_to_visit = directives

          while !@unvisited_types.empty? || !@late_bound_types.empty?
            while (type = @unvisited_types.pop)
              if @visited_types.add?(type) && @visit_block.call(type)
                directives_to_visit.concat(type.directives)
                case type.kind.name
                when "OBJECT", "INTERFACE"
                  type.interface_type_memberships.each do |itm|
                    append_unvisited_type(type, itm.abstract_type)
                  end
                  if type.kind.interface?
                    type.orphan_types.each do |orphan_type|
                      append_unvisited_type(type, orphan_type)
                    end
                  end

                  type.all_field_definitions.each do |field|
                    field.ensure_loaded
                    if @visit_block.call(field)
                      directives_to_visit.concat(field.directives)
                      append_unvisited_type(type, field.type.unwrap)
                      field.all_argument_definitions.each do |argument|
                        if @visit_block.call(argument)
                          directives_to_visit.concat(argument.directives)
                          append_unvisited_type(field, argument.type.unwrap)
                        end
                      end
                    end
                  end
                when "INPUT_OBJECT"
                  type.all_argument_definitions.each do |argument|
                    if @visit_block.call(argument)
                      directives_to_visit.concat(argument.directives)
                      append_unvisited_type(type, argument.type.unwrap)
                    end
                  end
                when "UNION"
                  type.type_memberships.each do |tm|
                    append_unvisited_type(type, tm.object_type)
                  end
                when "ENUM"
                  type.all_enum_value_definitions.each do |val|
                    if @visit_block.call(val)
                      directives_to_visit.concat(val.directives)
                    end
                  end
                when "SCALAR"
                  # pass -- nothing else to visit
                else
                  raise "Invariant: unhandled type kind: #{type.kind.inspect}"
                end
              end
            end

            directives_to_visit.each do |dir|
              dir_class = dir.is_a?(Class) ? dir : dir.class
              if @visited_directives.add?(dir_class) && @visit_block.call(dir_class)
                dir_class.all_argument_definitions.each do |arg_defn|
                  if @visit_block.call(arg_defn)
                    directives_to_visit.concat(arg_defn.directives)
                    append_unvisited_type(dir_class, arg_defn.type.unwrap)
                  end
                end
              end
            end

            missed_late_types_streak = 0
            while (owner, late_type = @late_bound_types.shift)
              if (late_type.is_a?(String) && (type = Member::BuildType.constantize(type))) ||
                  (late_type.is_a?(LateBoundType) && (type = @visited_types.find { |t| t.graphql_name == late_type.graphql_name }))
                missed_late_types_streak = 0 # might succeed next round
                update_type_owner(owner, type)
                append_unvisited_type(owner, type)
              else
                # Didn't find it -- keep trying
                missed_late_types_streak += 1
                @late_bound_types << [owner, late_type]
                if missed_late_types_streak == @late_bound_types.size
                  raise UnresolvedLateBoundTypeError.new(type: late_type)
                end
              end
            end
          end

          @unvisited_types = nil
          nil
        end

        private

        def append_unvisited_type(owner, type)
          if type.is_a?(LateBoundType) || type.is_a?(String)
            @late_bound_types << [owner, type]
          else
            @unvisited_types << type
          end
        end

        def update_type_owner(owner, type)
          case owner
          when Module
            if owner.kind.union?
              owner.assign_type_membership_object_type(type)
            elsif type.kind.interface?
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
                  if indirect_int.is_a?(LateBoundType) && (indirect_int_type = get_type(indirect_int.graphql_name)) # rubocop:disable Development/ContextIsPassedCop
                    update_type_owner(owner, indirect_int_type)
                  end
                end
              end
            end
          when GraphQL::Schema::Argument, GraphQL::Schema::Field
            orig_type = owner.type
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
          else
            raise "Unexpected update: #{owner.inspect} #{type.inspect}"
          end
        end
      end
    end
  end
end
