# frozen_string_literal: true

require "graphql/schema/find_inherited_value"

module GraphQL
  class Schema
    class Member
      # DSL methods shared by lots of things in the GraphQL Schema.
      # @api private
      # @see Classes that extend this, eg {GraphQL::Schema::Object}
      module BaseDSLMethods
        include GraphQL::Schema::FindInheritedValue

        # Call this with a new name to override the default name for this schema member; OR
        # call it without an argument to get the name of this schema member
        #
        # The default name is implemented in default_graphql_name
        # @param new_name [String]
        # @return [String]
        def graphql_name(new_name = nil)
          if new_name
            GraphQL::NameValidator.validate!(new_name)
            @graphql_name = new_name
          else
            @graphql_name ||= default_graphql_name
          end
        end

        # Just a convenience method to point out that people should use graphql_name instead
        def name(new_name = nil)
          return super() if new_name.nil?

          fail(
            "The new name override method is `graphql_name`, not `name`. Usage: "\
            "graphql_name \"#{new_name}\""
          )
        end

        # Call this method to provide a new description; OR
        # call it without an argument to get the description
        # @param new_description [String]
        # @return [String]
        def description(new_description = nil)
          if new_description
            @description = new_description
          elsif defined?(@description)
            @description
          else
            @description = nil
          end
        end

        # Call this method to provide a new comment; OR
        # call it without an argument to get the comment
        # @param new_comment [String]
        # @return [String, nil]
        def comment(new_comment = NOT_CONFIGURED)
          if !NOT_CONFIGURED.equal?(new_comment)
            @comment = new_comment
          elsif defined?(@comment)
            @comment
          else
            nil
          end
        end

        # This pushes some configurations _down_ the inheritance tree,
        # in order to prevent repetitive lookups at runtime.
        module ConfigurationExtension
          def inherited(child_class)
            child_class.introspection(introspection)
            child_class.description(description)
            child_class.comment(nil)
            child_class.default_graphql_name = nil

            if defined?(@graphql_name) && @graphql_name && (self.name.nil? || graphql_name != default_graphql_name)
              child_class.graphql_name(graphql_name)
            else
              child_class.graphql_name = nil
            end
            super
          end
        end

        # @return [Boolean] If true, this object is part of the introspection system
        def introspection(new_introspection = nil)
          if !new_introspection.nil?
            @introspection = new_introspection
          elsif defined?(@introspection)
            @introspection
          else
            false
          end
        end

        def introspection?
          !!@introspection
        end

        # The mutation this type was derived from, if it was derived from a mutation
        # @return [Class]
        def mutation(mutation_class = nil)
          if mutation_class
            @mutation = mutation_class
          elsif defined?(@mutation)
            @mutation
          else
            nil
          end
        end

        alias :unwrap :itself

        # Creates the default name for a schema member.
        # The default name is the Ruby constant name,
        # without any namespaces and with any `-Type` suffix removed
        def default_graphql_name
          @default_graphql_name ||= begin
            raise GraphQL::RequiredImplementationMissingError, 'Anonymous class should declare a `graphql_name`' if name.nil?
            g_name = -name.split("::").last
            g_name.end_with?("Type") ? g_name.sub(/Type\Z/, "") : g_name
          end
        end

        def visible?(context)
          true
        end

        def authorized?(object, context)
          true
        end

        def default_relay
          false
        end

        protected

        attr_writer :default_graphql_name, :graphql_name
      end
    end
  end
end
