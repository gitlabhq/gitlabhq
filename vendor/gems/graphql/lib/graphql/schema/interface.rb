# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      include GraphQL::Schema::Member::GraphQLTypeNames
      module DefinitionMethods
        include GraphQL::Schema::Member::BaseDSLMethods
        # ConfigurationExtension's responsibilities are in `def included` below
        include GraphQL::Schema::Member::TypeSystemHelpers
        include GraphQL::Schema::Member::HasFields
        include GraphQL::Schema::Member::HasPath
        include GraphQL::Schema::Member::RelayShortcuts
        include GraphQL::Schema::Member::Scoped
        include GraphQL::Schema::Member::HasAstNode
        include GraphQL::Schema::Member::HasUnresolvedTypeError
        include GraphQL::Schema::Member::HasDataloader
        include GraphQL::Schema::Member::HasDirectives
        include GraphQL::Schema::Member::HasInterfaces

        # Methods defined in this block will be:
        # - Added as class methods to this interface
        # - Added as class methods to all child interfaces
        def definition_methods(&block)
          # Use an instance variable to tell whether it's been included previously or not;
          # You can't use constant detection because constants are brought into scope
          # by `include`, which has already happened at this point.
          if !defined?(@_definition_methods)
            defn_methods_module = Module.new
            @_definition_methods = defn_methods_module
            const_set(:DefinitionMethods, defn_methods_module)
            extend(self::DefinitionMethods)
          end
          self::DefinitionMethods.module_exec(&block)
        end

        # @see {Schema::Warden} hides interfaces without visible implementations
        def visible?(context)
          true
        end

        def type_membership_class(membership_class = nil)
          if membership_class
            @type_membership_class = membership_class
          else
            @type_membership_class || find_inherited_value(:type_membership_class, GraphQL::Schema::TypeMembership)
          end
        end

        # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
        def included(child_class)
          if !child_class.is_a?(Class)
            # In this case, it's been included into another interface.
            # This is how interface inheritance is implemented

            # We need this before we can call `own_interfaces`
            child_class.extend(Schema::Interface::DefinitionMethods)

            child_class.type_membership_class(self.type_membership_class)
            child_class.ancestors.reverse_each do |ancestor|
              if ancestor.const_defined?(:DefinitionMethods) && ancestor != child_class
                child_class.extend(ancestor::DefinitionMethods)
              end
            end

            child_class.introspection(introspection)
            child_class.description(description)
            child_class.comment(nil)
            # If interfaces are mixed into each other, only define this class once
            if !child_class.const_defined?(:UnresolvedTypeError, false)
              add_unresolved_type_error(child_class)
            end
          elsif child_class < GraphQL::Schema::Object
            # This is being included into an object type, make sure it's using `implements(...)`
            backtrace_line = caller_locations(0, 10).find do |location|
              location.base_label == "implements" &&
                location.path.end_with?("schema/member/has_interfaces.rb")
            end

            if !backtrace_line
              raise "Attach interfaces using `implements(#{self})`, not `include(#{self})`"
            end
          end

          super
        end

        # Register other Interface or Object types as implementers of this Interface.
        #
        # When those Interfaces or Objects aren't used as the return values of fields,
        # they may have to be registered using this method so that GraphQL-Ruby can find them.
        # @param types [Class, Module]
        # @return [Array<Module, Class>] Implementers of this interface, if they're registered
        def orphan_types(*types)
          if !types.empty?
            @orphan_types ||= []
            @orphan_types.concat(types)
          else
            if defined?(@orphan_types)
              all_orphan_types = @orphan_types.dup
              if defined?(super)
                all_orphan_types += super
                all_orphan_types.uniq!
              end
              all_orphan_types
            elsif defined?(super)
              super
            else
              EmptyObjects::EMPTY_ARRAY
            end
          end
        end

        def kind
          GraphQL::TypeKinds::INTERFACE
        end
      end

      extend DefinitionMethods

      def unwrap
        self
      end
    end
  end
end
