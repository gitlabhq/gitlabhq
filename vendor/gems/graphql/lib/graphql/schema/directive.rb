# frozen_string_literal: true

module GraphQL
  class Schema
    # Subclasses of this can influence how {GraphQL::Execution::Interpreter} runs queries.
    #
    # - {.include?}: if it returns `false`, the field or fragment will be skipped altogether, as if it were absent
    # - {.resolve}: Wraps field resolution (so it should call `yield` to continue)
    class Directive < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasArguments
      extend GraphQL::Schema::Member::HasArguments::HasDirectiveArguments

      class << self
        # Directives aren't types, they don't have kinds.
        undef_method :kind

        def path
          "@#{super}"
        end

        # Return a name based on the class name,
        # but downcase the first letter.
        def default_graphql_name
          @default_graphql_name ||= begin
            camelized_name = super.dup
            camelized_name[0] = camelized_name[0].downcase
            -camelized_name
          end
        end

        def locations(*new_locations)
          if !new_locations.empty?
            new_locations.each do |new_loc|
              if !LOCATIONS.include?(new_loc.to_sym)
                raise ArgumentError, "#{self} (#{self.graphql_name}) has an invalid directive location: `locations #{new_loc}` "
              end
            end
            @locations = new_locations
          else
            @locations ||= (superclass.respond_to?(:locations) ? superclass.locations : [])
          end
        end

        def default_directive(new_default_directive = nil)
          if new_default_directive != nil
            @default_directive = new_default_directive
          elsif @default_directive.nil?
            @default_directive = (superclass.respond_to?(:default_directive) ? superclass.default_directive : false)
          else
            !!@default_directive
          end
        end

        def default_directive?
          default_directive
        end

        # If false, this part of the query won't be evaluated
        def include?(_object, arguments, context)
          static_include?(arguments, context)
        end

        # Determines whether {Execution::Lookahead} considers the field to be selected
        def static_include?(_arguments, _context)
          true
        end

        # Continuing is passed as a block; `yield` to continue
        def resolve(object, arguments, context)
          yield
        end

        # Continuing is passed as a block, yield to continue.
        def resolve_each(object, arguments, context)
          yield
        end

        def on_field?
          locations.include?(FIELD)
        end

        def on_fragment?
          locations.include?(FRAGMENT_SPREAD) && locations.include?(INLINE_FRAGMENT)
        end

        def on_operation?
          locations.include?(QUERY) && locations.include?(MUTATION) && locations.include?(SUBSCRIPTION)
        end

        def repeatable?
          !!@repeatable
        end

        def repeatable(new_value)
          @repeatable = new_value
        end

        private

        def inherited(subclass)
          super
          subclass.class_exec do
            @default_graphql_name ||= nil
          end
        end
      end

      # @return [GraphQL::Schema::Field, GraphQL::Schema::Argument, Class, Module]
      attr_reader :owner

      # @return [GraphQL::Interpreter::Arguments]
      attr_reader :arguments

      def initialize(owner, **arguments)
        @owner = owner
        assert_valid_owner
        # It's be nice if we had the real context here, but we don't. What we _would_ get is:
        # - error handling
        # - lazy resolution
        # Probably, those won't be needed here, since these are configuration arguments,
        # not runtime arguments.
        @arguments = self.class.coerce_arguments(nil, arguments, Query::NullContext.instance)
      end

      def graphql_name
        self.class.graphql_name
      end

      LOCATIONS = [
        QUERY =                  :QUERY,
        MUTATION =               :MUTATION,
        SUBSCRIPTION =           :SUBSCRIPTION,
        FIELD =                  :FIELD,
        FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
        FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
        INLINE_FRAGMENT =        :INLINE_FRAGMENT,
        SCHEMA =                 :SCHEMA,
        SCALAR =                 :SCALAR,
        OBJECT =                 :OBJECT,
        FIELD_DEFINITION =       :FIELD_DEFINITION,
        ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
        INTERFACE =              :INTERFACE,
        UNION =                  :UNION,
        ENUM =                   :ENUM,
        ENUM_VALUE =             :ENUM_VALUE,
        INPUT_OBJECT =           :INPUT_OBJECT,
        INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
        VARIABLE_DEFINITION =    :VARIABLE_DEFINITION,
      ]

      DEFAULT_DEPRECATION_REASON = 'No longer supported'
      LOCATION_DESCRIPTIONS = {
        QUERY:                    'Location adjacent to a query operation.',
        MUTATION:                 'Location adjacent to a mutation operation.',
        SUBSCRIPTION:             'Location adjacent to a subscription operation.',
        FIELD:                    'Location adjacent to a field.',
        FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
        FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
        INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
        SCHEMA:                   'Location adjacent to a schema definition.',
        SCALAR:                   'Location adjacent to a scalar definition.',
        OBJECT:                   'Location adjacent to an object type definition.',
        FIELD_DEFINITION:         'Location adjacent to a field definition.',
        ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
        INTERFACE:                'Location adjacent to an interface definition.',
        UNION:                    'Location adjacent to a union definition.',
        ENUM:                     'Location adjacent to an enum definition.',
        ENUM_VALUE:               'Location adjacent to an enum value definition.',
        INPUT_OBJECT:             'Location adjacent to an input object type definition.',
        INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
        VARIABLE_DEFINITION:      'Location adjacent to a variable definition.',
      }

      private

      def assert_valid_owner
        case @owner
        when Class
          if @owner < GraphQL::Schema::Object
            assert_has_location(OBJECT)
          elsif @owner < GraphQL::Schema::Union
            assert_has_location(UNION)
          elsif @owner < GraphQL::Schema::Enum
            assert_has_location(ENUM)
          elsif @owner < GraphQL::Schema::InputObject
            assert_has_location(INPUT_OBJECT)
          elsif @owner < GraphQL::Schema::Scalar
            assert_has_location(SCALAR)
          elsif @owner < GraphQL::Schema
            assert_has_location(SCHEMA)
          elsif @owner < GraphQL::Schema::Resolver
            assert_has_location(FIELD_DEFINITION)
          else
            raise "Unexpected directive owner class: #{@owner}"
          end
        when Module
          assert_has_location(INTERFACE)
        when GraphQL::Schema::Argument
          if @owner.owner.is_a?(GraphQL::Schema::Field)
            assert_has_location(ARGUMENT_DEFINITION)
          else
            assert_has_location(INPUT_FIELD_DEFINITION)
          end
        when GraphQL::Schema::Field
          assert_has_location(FIELD_DEFINITION)
        when GraphQL::Schema::EnumValue
          assert_has_location(ENUM_VALUE)
        else
          raise "Unexpected directive owner: #{@owner.inspect}"
        end
      end

      def assert_has_location(location)
        if !self.class.locations.include?(location)
          raise ArgumentError, <<-MD
Directive `@#{self.class.graphql_name}` can't be attached to #{@owner.graphql_name} because #{location} isn't included in its locations (#{self.class.locations.join(", ")}).

Use `locations(#{location})` to update this directive's definition, or remove it from #{@owner.graphql_name}.
MD
        end
      end
    end
  end
end
