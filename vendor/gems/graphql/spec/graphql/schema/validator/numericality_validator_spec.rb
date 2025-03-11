# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::NumericalityValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { less_than: 10, greater_than: 2, allow_null: true },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 12) }", result: nil, error_messages: ["value must be less than 10"] },
        { query: "{ validated(value: 1) }", result: nil, error_messages: ["value must be greater than 2"] },
        { query: "{ validated(value: null) }", result: nil, error_messages: [] },
      ]
    },
    {
      config: { less_than_or_equal_to: 10, greater_than_or_equal_to: 2 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 10) }", result: 10, error_messages: [] },
        { query: "{ validated(value: 2) }", result: 2, error_messages: [] },
        { query: "{ validated(value: 12) }", result: nil, error_messages: ["value must be less than or equal to 10"] },
        { query: "{ validated(value: 1) }", result: nil, error_messages: ["value must be greater than or equal to 2"] },
      ]
    },
    {
      config: { odd: true },
      cases: [
        { query: "{ validated(value: 9) }", result: 9, error_messages: [] },
        { query: "{ validated(value: 8) }", result: nil, error_messages: ["value must be odd"] },
      ]
    },
    {
      config: { even: true },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be even"] },
      ]
    },
    {
      config: { equal_to: 8 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be equal to 8"] },
      ]
    },
    {
      config: { other_than: 9 },
      cases: [
        { query: "{ validated(value: 8) }", result: 8, error_messages: [] },
        { query: "{ validated(value: null) }", result: nil, error_messages: ["value can't be null"] },
        { query: "{ validated(value: 9) }", result: nil, error_messages: ["value must be something other than 9"] },
      ]
    },
    {
      config: { within: 1..5, allow_null: true },
      cases: [
        { query: "{ validated(value: 1) }", result: 1, error_messages: [] },
        { query: "{ validated(value: 5) }", result: 5, error_messages: [] },
        { query: "{ validated(value: 0) }", result: nil, error_messages: ["value must be within 1..5"] },
        { query: "{ validated(value: 6) }", result: nil, error_messages: ["value must be within 1..5"] },
      ]
    },
  ]

  build_tests(:numericality, Integer, expectations)
end
