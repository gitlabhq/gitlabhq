# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # Use this to assert that string values match (or don't match) the given RegExp.
      #
      # @example requiring input to match a pattern
      #
      #   argument :handle, String, required: true,
      #     validates: { format: { with: /\A[a-z0-9_]+\Z/ } }
      #
      # @example reject inputs that match a pattern
      #
      #   argument :word_that_doesnt_begin_with_a_vowel, String, required: true,
      #     validates: { format: { without: /\A[aeiou]/ } }
      #
      #   # It's pretty hard to come up with a legitimate use case for `without:`
      #
      class FormatValidator < Validator
        # @param with [RegExp, nil]
        # @param without [Regexp, nil]
        # @param message [String]
        def initialize(
          with: nil,
          without: nil,
          message: "%{validated} is invalid",
          **default_options
        )
          @with_pattern = with
          @without_pattern = without
          @message = message
          super(**default_options)
        end

        def validate(_object, _context, value)
          if permitted_empty_value?(value)
            # Do nothing
          elsif value.nil? ||
              (@with_pattern && !value.match?(@with_pattern)) ||
              (@without_pattern && value.match?(@without_pattern))
            @message
          end
        end
      end
    end
  end
end
