# frozen_string_literal: true

# AccessMatchersForRequest
#
# Matchers to test the access permissions for requests specs (most useful for API tests).
module AccessMatchersForRequest
  extend RSpec::Matchers::DSL
  include AccessMatchersHelpers

  EXPECTED_STATUS_CODES_ALLOWED = [200, 201, 204, 302, 304].freeze
  EXPECTED_STATUS_CODES_DENIED = [401, 403, 404].freeze

  def description_for(role, type, expected, result)
    "be #{type} for #{role} role. Expected status code: any of #{expected.join(', ')} Got: #{result}"
  end

  matcher :be_allowed_for do |role|
    match do |action|
      # methods called in this and negated block are being run in context of ExampleGroup
      # (not matcher) instance so we have to pass data via local vars

      run_matcher(action, role, @membership, @owned_objects)

      EXPECTED_STATUS_CODES_ALLOWED.include?(response.status)
    end

    match_when_negated do |action|
      run_matcher(action, role, @membership, @owned_objects)

      EXPECTED_STATUS_CODES_DENIED.include?(response.status)
    end

    chain :of do |membership|
      @membership = membership
    end

    chain :own do |*owned_objects|
      @owned_objects = owned_objects
    end

    failure_message do
      "expected this action to #{description_for(role, 'allowed', EXPECTED_STATUS_CODES_ALLOWED, response.status)}"
    end

    failure_message_when_negated do
      "expected this action to #{description_for(role, 'denied', EXPECTED_STATUS_CODES_DENIED, response.status)}"
    end

    supports_block_expectations
  end

  RSpec::Matchers.define_negated_matcher :be_denied_for, :be_allowed_for
end
