# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasInterfaces
        def implements(*new_interfaces, **options)
          new_memberships = []
          new_interfaces.each do |int|
            if int.is_a?(Module)
              unless int.include?(GraphQL::Schema::Interface)
                raise "#{int} cannot be implemented since it's not a GraphQL Interface. Use `include` for plain Ruby modules."
              end

              new_memberships << int.type_membership_class.new(int, self, **options)

              # Include the methods here,
              # `.fields` will use the inheritance chain
              # to find inherited fields
              include(int)

              # If this interface has interfaces of its own, add those, too
              int.interfaces.each do |next_interface|
                implements(next_interface)
              end
            elsif int.is_a?(String) || int.is_a?(GraphQL::Schema::LateBoundType)
              if !options.empty?
                raise ArgumentError, "`implements(...)` doesn't support options with late-loaded types yet. Remove #{options} and open an issue to request this feature."
              end
              new_memberships << int
            else
              raise ArgumentError, "Unexpected interface definition (expected module): #{int} (#{int.class})"
            end
          end

          # Remove any String or late-bound interfaces which are being replaced
          own_interface_type_memberships.reject! { |old_i_m|
            if !(old_i_m.respond_to?(:abstract_type) && old_i_m.abstract_type.is_a?(Module))
              old_int_type = old_i_m.respond_to?(:abstract_type) ? old_i_m.abstract_type : old_i_m
              old_name = Schema::Member::BuildType.to_type_name(old_int_type)

              new_memberships.any? { |new_i_m|
                new_int_type = new_i_m.respond_to?(:abstract_type) ? new_i_m.abstract_type : new_i_m
                new_name = Schema::Member::BuildType.to_type_name(new_int_type)

                new_name == old_name
              }
            end
          }
          own_interface_type_memberships.concat(new_memberships)
        end

        def own_interface_type_memberships
          @own_interface_type_memberships ||= []
        end

        def interface_type_memberships
          own_interface_type_memberships
        end

        module ClassConfigured
          # This combination of extended -> inherited -> extended
          # means that the base class (`Schema::Object`) *won't*
          # have the superclass-related code in `InheritedInterfaces`,
          # but child classes of `Schema::Object` will have it.
          # That way, we don't need a `superclass.respond_to?(...)` check.
          def inherited(child_class)
            super
            child_class.extend(InheritedInterfaces)
          end

          module InheritedInterfaces
            def interfaces(context = GraphQL::Query::NullContext.instance)
              visible_interfaces = super
              inherited_interfaces = superclass.interfaces(context)
              if !visible_interfaces.empty?
                if !inherited_interfaces.empty?
                  visible_interfaces.concat(inherited_interfaces)
                  visible_interfaces.uniq!
                end
                visible_interfaces
              elsif !inherited_interfaces.empty?
                inherited_interfaces
              else
                EmptyObjects::EMPTY_ARRAY
              end
            end

            def interface_type_memberships
              own_tms = super
              inherited_tms = superclass.interface_type_memberships
              if inherited_tms.size > 0
                own_tms + inherited_tms
              else
                own_tms
              end
            end
          end
        end

        # param context [Query::Context] If omitted, skip filtering.
        def interfaces(context = GraphQL::Query::NullContext.instance)
          warden = Warden.from_context(context)
          visible_interfaces = nil
          own_interface_type_memberships.each do |type_membership|
            case type_membership
            when Schema::TypeMembership
              if warden.visible_type_membership?(type_membership, context)
                visible_interfaces ||= []
                visible_interfaces << type_membership.abstract_type
              end
            when String, Schema::LateBoundType
              # During initialization, `type_memberships` can hold late-bound types
              visible_interfaces ||= []
              visible_interfaces << type_membership
            else
              raise "Invariant: Unexpected type_membership #{type_membership.class}: #{type_membership.inspect}"
            end
          end
          if visible_interfaces
            visible_interfaces.uniq!
            visible_interfaces
          else
            EmptyObjects::EMPTY_ARRAY
          end
        end

        private

        def self.extended(child_class)
          child_class.extend(ClassConfigured)
        end

        def inherited(subclass)
          super
          subclass.class_exec do
            @own_interface_type_memberships ||= nil
          end
        end
      end
    end
  end
end
