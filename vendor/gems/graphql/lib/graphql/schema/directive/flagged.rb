# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      # This is _similar_ to {Directive::Feature}, except it's prescribed by the server, not the client.
      #
      # In this case, the server hides types and fields _entirely_, unless the current context has certain `:flags` present.
      class Flagged < GraphQL::Schema::Directive
        def initialize(target, **options)
          if target.is_a?(Module)
            # This is type class of some kind, `include` will put this module
            # in between the type class itself and its super class, so `super` will work fine
            target.include(VisibleByFlag)
          elsif !target.is_a?(VisibleByFlag)
            # This is an instance of a base class. `include` won't put this in front of the
            # base class implementation, so we need to `.prepend`.
            # `#visible?` could probably be moved to a module and then this could use `include` instead.
            target.class.prepend(VisibleByFlag)
          end
          super
        end

        description "Hides this part of the schema unless the named flag is present in context[:flags]"

        locations(
          GraphQL::Schema::Directive::FIELD_DEFINITION,
          GraphQL::Schema::Directive::OBJECT,
          GraphQL::Schema::Directive::SCALAR,
          GraphQL::Schema::Directive::ENUM,
          GraphQL::Schema::Directive::UNION,
          GraphQL::Schema::Directive::INTERFACE,
          GraphQL::Schema::Directive::INPUT_OBJECT,
          GraphQL::Schema::Directive::ENUM_VALUE,
          GraphQL::Schema::Directive::ARGUMENT_DEFINITION,
          GraphQL::Schema::Directive::INPUT_FIELD_DEFINITION,
        )

        argument :by, [String], "Flags to check for this schema member"

        module VisibleByFlag
          def self.included(schema_class)
            schema_class.extend(self)
          end

          def visible?(context)
            if dir = self.directives.find { |d| d.is_a?(Flagged) }
              relevant_flags = (f = context[:flags]) && dir.arguments[:by] & f # rubocop:disable Development/ContextIsPassedCop -- definition-related
              relevant_flags && !relevant_flags.empty? && super
            else
              super
            end
          end
        end
      end
    end
  end
end
