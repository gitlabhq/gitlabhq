# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::AllValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { format: { with: /\A[a-z]+\Z/ } },
      cases: [
        { query: "{ validated(value: []) }", result: [], error_messages: [] },
        { query: "{ validated(value: [\"abc\"]) }", result: ["abc"], error_messages: [] },
        { query: "{ validated(value: [\"abc\", \"def\"]) }", result: ["abc", "def"], error_messages: [] },
        { query: "{ validated(value: [\"ABC\"]) }", result: nil, error_messages: ["value is invalid"] },
        { query: "{ validated(value: [\"abc\", \"DEF\"]) }", result: nil, error_messages: ["value is invalid"] },
        { query: "{ validated(value: [\"abc\", \"DEF\", \"GHI\"]) }", result: nil, error_messages: ["value is invalid"] },
      ],
    },
    {
      config: { format: { with: /\A[a-z]+\Z/ }, length: { maximum: 2 } },
      cases: [
        { query: "{ validated(value: []) }", result: [], error_messages: [] },
        { query: "{ validated(value: [\"a\"]) }", result: ["a"], error_messages: [] },
        { query: "{ validated(value: [\"a\", \"bc\"]) }", result: ["a", "bc"], error_messages: [] },
        { query: "{ validated(value: [\"AB\"]) }", result: nil, error_messages: ["value is invalid"] },
        { query: "{ validated(value: [\"abc\"]) }", result: nil, error_messages: ["value is too long (maximum is 2)"] },
        { query: "{ validated(value: [\"ABC\"]) }", result: nil, error_messages: ["value is invalid, value is too long (maximum is 2)"] },
        { query: "{ validated(value: [\"ABC\", \"DEF\"]) }", result: nil, error_messages: ["value is invalid, value is too long (maximum is 2)"] },
      ],
    },
  ]

  build_tests(:all, [String], expectations)

  expectations = [
    {
      config: { inclusion: { in: 1..3 } },
      cases: [
        { query: "{ validated(value: []) }", result: [], error_messages: [] },
        { query: "{ validated(value: [1]) }", result: [1], error_messages: [] },
        { query: "{ validated(value: [1, 2]) }", result: [1, 2], error_messages: [] },
        { query: "{ validated(value: [4]) }", result: nil, error_messages: ["value is not included in the list"] },
        { query: "{ validated(value: [1, 4]) }", result: nil, error_messages: ["value is not included in the list"] },
        { query: "{ validated(value: [1, 4, 5]) }", result: nil, error_messages: ["value is not included in the list"] },
      ],
    },
  ]

  build_tests(:all, [Integer], expectations)

  expectations = [
    {
      config: { allow_null: true, inclusion: { in: 1..5 }, numericality: { odd: true } },
      cases: [
        { query: "{ validated(value: null) }", result: nil, error_messages: [] },
        { query: "{ validated(value: []) }", result: [], error_messages: [] },
        { query: "{ validated(value: [1]) }", result: [1], error_messages: [] },
        { query: "{ validated(value: [1, 3]) }", result: [1, 3], error_messages: [] },
        { query: "{ validated(value: [4]) }", result: nil, error_messages: ["value must be odd"] },
        { query: "{ validated(value: [7]) }", result: nil, error_messages: ["value is not included in the list"] },
      ],
    },
  ]

  build_tests(:all, [Integer], expectations)
end
