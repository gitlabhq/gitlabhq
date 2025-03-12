# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # A container for metadata regarding arguments present in a GraphQL query.
      # @see Interpreter::Arguments#argument_values for a hash of these objects.
      class ArgumentValue
        def initialize(definition:, value:, original_value:, default_used:)
          @definition = definition
          @value = value
          @original_value = original_value
          @default_used = default_used
        end

        # @return [Object] The Ruby-ready value for this Argument
        attr_reader :value

        # @return [Object] The value of this argument _before_ `prepare` is applied.
        attr_reader :original_value

        # @return [GraphQL::Schema::Argument] The definition instance for this argument
        attr_reader :definition

        # @return [Boolean] `true` if the schema-defined `default_value:` was applied in this case. (No client-provided value was present.)
        def default_used?
          @default_used
        end
      end
    end
  end
end
