# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to specifically reject values from an argument.
      #
      # @example disallow certain values
      #
      #   argument :favorite_non_prime, Integer, required: true,
      #     validates: { exclusion: { in: [2, 3, 5, 7, ... ]} }
      #
      class ExclusionValidator < Validator
        # @param message [String]
        # @param in [Array] The values to reject
        def initialize(message: "%{validated} is reserved", in:, **default_options)
          # `in` is a reserved word, so work around that
          @in_list = binding.local_variable_get(:in)
          @message = message
          super(**default_options)
        end

        def validate(_object, _context, value)
          if permitted_empty_value?(value)
            # pass
          elsif @in_list.include?(value)
            @message
          end
        end
      end
    end
  end
end
