# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::InclusionValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { in: [1, 2, 3] },
      cases: [
        { query: "{ validated(value: 1) }", result: 1, error_messages: [] },
        { query: "{ validated(value: null) }", result: nil, error_messages: ["value is not included in the list"] },
        { query: "{ validated(value: 10) }", result: nil, error_messages: ["value is not included in the list"] },
      ]
    },
    {
      config: { in: [1, 2, 3], allow_null: true },
      cases: [
        { query: "{ validated(value: 1) }", result: 1, error_messages: [] },
        { query: "{ validated(value: null) }", result: nil, error_messages: [] },
        { query: "{ validated(value: 10) }", result: nil, error_messages: ["value is not included in the list"] },
      ]
    },
  ]

  build_tests(:inclusion, Integer, expectations)
end
