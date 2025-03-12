# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # You can use this to allow certain values for an argument.
      #
      # Usually, a {GraphQL::Schema::Enum} is better for this, because it's self-documenting.
      #
      # @example only allow certain values for an argument
      #
      #   argument :favorite_prime, Integer, required: true,
      #     validates: { inclusion: { in: [2, 3, 5, 7, 11, ... ] } }
      #
      class InclusionValidator < Validator
        # @param message [String]
        # @param in [Array] The values to allow
        def initialize(in:, message: "%{validated} is not included in the list", **default_options)
          # `in` is a reserved word, so work around that
          @in_list = binding.local_variable_get(:in)
          @message = message
          super(**default_options)
        end

        def validate(_object, _context, value)
          if permitted_empty_value?(value)
            # pass
          elsif !@in_list.include?(value)
            @message
          end
        end
      end
    end
  end
end
