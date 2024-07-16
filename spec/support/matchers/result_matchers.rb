# frozen_string_literal: true

# Example usage:
#
#   expect(Result.ok(1)).to be_ok_result(1)
#
#   expect(Result.err('hello')).to be_err_result do |result_value|
#     expect(result_value).to match(/hello/i)
#   end
#
# Argument to matcher is the expected value to be matched via '=='.
# For more complex matching, pass a block to the matcher which will receive the result value as an argument.

module ResultMatchers
  def be_ok_result(expected_value = nil)
    BeResult.new(ok_or_err: :ok, expected_value: expected_value)
  end

  def be_err_result(expected_value = nil)
    BeResult.new(ok_or_err: :err, expected_value: expected_value)
  end

  class BeResult
    attr_reader :ok_or_err, :actual, :failure_message_suffix, :expected_value

    def initialize(ok_or_err:, expected_value:)
      @ok_or_err = ok_or_err
      @expected_value = expected_value
    end

    def matches?(actual, &block)
      @actual = actual

      raise "#{actual} must be a Result, but it was a #{actual.class}" unless actual.is_a?(Gitlab::Fp::Result)

      @failure_message_suffix = "be an '#{ok_or_err}' type"
      return false unless actual.ok? == ok?

      actual_value = actual.ok? ? actual.unwrap : actual.unwrap_err

      if expected_value
        @failure_message_suffix =
          "have a value of #{expected_value.inspect}, but it was #{actual_value.inspect}"
        return false unless actual_value == expected_value
      end

      # NOTE: A block can be passed to the matcher to perform more sophisticated matching,
      #       or to provide more concise and specific failure messages.
      block ? block.yield(actual_value) : true
    end

    def failure_message
      "expected #{actual.inspect} to #{failure_message_suffix}"
    end

    def failure_message_when_negated
      "expected #{actual.inspect} not to #{failure_message_suffix}"
    end

    private

    def ok?
      ok_or_err == :ok
    end
  end
end
