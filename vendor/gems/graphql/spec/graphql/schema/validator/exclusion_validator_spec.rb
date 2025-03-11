# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::ExclusionValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { in: [1, 2, 3] },
      cases: [
        { query: "{ validated(value: 1) }", result: nil, error_messages: ["value is reserved"] },
        { query: "{ validated(value: null) }", result: nil, error_messages: [] },
        { query: "{ validated(value: 10) }", result: 10, error_messages: [] },
      ]
    },
  ]

  build_tests(:exclusion, Integer, expectations)
end
