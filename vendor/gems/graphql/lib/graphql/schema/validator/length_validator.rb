# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to enforce a `.length` restriction on incoming values. It works for both Strings and Lists.
      #
      # @example Allow no more than 10 IDs
      #
      #   argument :ids, [ID], required: true, validates: { length: { maximum: 10 } }
      #
      # @example Require three selections
      #
      #   argument :ice_cream_preferences, [ICE_CREAM_FLAVOR], required: true, validates: { length: { is: 3 } }
      #
      class LengthValidator < Validator
        # @param maximum [Integer]
        # @param too_long [String] Used when `maximum` is exceeded or value is greater than `within`
        # @param minimum [Integer]
        # @param too_short [String] Used with value is less than `minimum` or less than `within`
        # @param is [Integer] Exact length requirement
        # @param wrong_length [String] Used when value doesn't match `is`
        # @param within [Range] An allowed range (becomes `minimum:` and `maximum:` under the hood)
        # @param message [String]
        def initialize(
          maximum: nil, too_long: "%{validated} is too long (maximum is %{count})",
          minimum: nil, too_short: "%{validated} is too short (minimum is %{count})",
          is: nil, within: nil, wrong_length: "%{validated} is the wrong length (should be %{count})",
          message: nil,
          **default_options
        )
          if within && (minimum || maximum)
            raise ArgumentError, "`length: { ... }` may include `within:` _or_ `minimum:`/`maximum:`, but not both"
          end
          # Under the hood, `within` is decomposed into `minimum` and `maximum`
          @maximum = maximum || (within && within.max)
          @too_long = message || too_long
          @minimum = minimum || (within && within.min)
          @too_short = message || too_short
          @is = is
          @wrong_length = message || wrong_length
          super(**default_options)
        end

        def validate(_object, _context, value)
          return if permitted_empty_value?(value) # pass in this case
          length = value.nil? ? 0 : value.length
          if @maximum && length > @maximum
            partial_format(@too_long, { count: @maximum })
          elsif @minimum && length < @minimum
            partial_format(@too_short, { count: @minimum })
          elsif @is && length != @is
            partial_format(@wrong_length, { count: @is })
          end
        end
      end
    end
  end
end
