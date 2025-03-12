# frozen_string_literal: true
module GraphQL
  class Schema
    class Validator
      # Use this to assert numerical comparisons hold true for inputs.
      #
      # @example Require a number between 0 and 1
      #
      #   argument :batting_average, Float, required: true, validates: { numericality: { within: 0..1 } }
      #
      # @example Require the number 42
      #
      #   argument :the_answer, Integer, required: true, validates: { numericality: { equal_to: 42 } }
      #
      # @example Require a real number
      #
      #   argument :items_count, Integer, required: true, validates: { numericality: { greater_than_or_equal_to: 0 } }
      #
      class NumericalityValidator < Validator
        # @param greater_than [Integer]
        # @param greater_than_or_equal_to [Integer]
        # @param less_than [Integer]
        # @param less_than_or_equal_to [Integer]
        # @param equal_to [Integer]
        # @param other_than [Integer]
        # @param odd [Boolean]
        # @param even [Boolean]
        # @param within [Range]
        # @param message [String] used for all validation failures
        def initialize(
            greater_than: nil, greater_than_or_equal_to: nil,
            less_than: nil, less_than_or_equal_to: nil,
            equal_to: nil, other_than: nil,
            odd: nil, even: nil, within: nil,
            message: "%{validated} must be %{comparison} %{target}",
            null_message: Validator::AllowNullValidator::MESSAGE,
            **default_options
          )

          @greater_than = greater_than
          @greater_than_or_equal_to = greater_than_or_equal_to
          @less_than = less_than
          @less_than_or_equal_to = less_than_or_equal_to
          @equal_to = equal_to
          @other_than = other_than
          @odd = odd
          @even = even
          @within = within
          @message = message
          @null_message = null_message
          super(**default_options)
        end

        def validate(object, context, value)
          if permitted_empty_value?(value)
            # pass in this case
          elsif value.nil? # @allow_null is handled in the parent class
            @null_message
          elsif @greater_than && value <= @greater_than
            partial_format(@message, { comparison: "greater than", target: @greater_than })
          elsif @greater_than_or_equal_to && value < @greater_than_or_equal_to
            partial_format(@message, { comparison: "greater than or equal to", target: @greater_than_or_equal_to })
          elsif @less_than && value >= @less_than
            partial_format(@message, { comparison: "less than", target: @less_than })
          elsif @less_than_or_equal_to && value > @less_than_or_equal_to
            partial_format(@message, { comparison: "less than or equal to", target: @less_than_or_equal_to })
          elsif @equal_to && value != @equal_to
            partial_format(@message, { comparison: "equal to", target: @equal_to })
          elsif @other_than && value == @other_than
            partial_format(@message, { comparison: "something other than", target: @other_than })
          elsif @even && !value.even?
            (partial_format(@message, { comparison: "even", target: "" })).strip
          elsif @odd && !value.odd?
            (partial_format(@message, { comparison: "odd", target: "" })).strip
          elsif @within && !@within.include?(value)
            partial_format(@message, { comparison: "within", target: @within })
          end
        end
      end
    end
  end
end
