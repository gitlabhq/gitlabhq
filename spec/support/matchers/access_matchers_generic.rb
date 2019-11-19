# frozen_string_literal: true

# AccessMatchersGeneric
#
# Matchers to test the access permissions for service classes or other generic pieces of business logic.
module AccessMatchersGeneric
  extend RSpec::Matchers::DSL
  include AccessMatchersHelpers

  ERROR_CLASS = Gitlab::Access::AccessDeniedError

  def error_message(error)
    str = error.class.name
    str += ": #{error.message}" if error.message != error.class.name
    str
  end

  def error_expectation_message(allowed, error)
    if allowed
      "Expected to raise nothing but #{error_message(error)} was raised."
    else
      "Expected to raise #{ERROR_CLASS} but nothing was raised."
    end
  end

  def description_for(role, type, error)
    allowed = type == 'allowed'
    "be #{type} for #{role} role. #{error_expectation_message(allowed, error)}"
  end

  matcher :be_allowed_for do |role|
    match do |action|
      # methods called in this and negated block are being run in context of ExampleGroup
      # (not matcher) instance so we have to pass data via local vars

      run_matcher(action, role, @membership, @owned_objects) do |action|
        action.call
      rescue => e
        @error = e
        raise unless e.is_a?(ERROR_CLASS)
      end

      @error.nil?
    end

    chain :of do |membership|
      @membership = membership
    end

    chain :own do |*owned_objects|
      @owned_objects = owned_objects
    end

    failure_message do
      "expected this action to #{description_for(role, 'allowed', @error)}"
    end

    failure_message_when_negated do
      "expected this action to #{description_for(role, 'denied', @error)}"
    end

    supports_block_expectations
  end

  RSpec::Matchers.define_negated_matcher :be_denied_for, :be_allowed_for
end
