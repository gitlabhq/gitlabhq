# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::RequiredValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { one_of: [:a, :b] },
      cases: [
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, b."] },
        { query: "{ validated: multiValidated(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: 4, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2) }", result: 2, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: 5, error_messages: [] },
      ]
    },
    {
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: multiValidated(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: multiValidated(b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "Definition order independence",
      config: { one_of: [[:a, :b], :c] },
      cases: [
        { query: "{ validated: multiValidated(c: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: multiValidated(a: 2, b: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: multiValidated }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 1, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(b: 2, c: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(a: 3) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
        { query: "{ validated: multiValidated(b: 2) }", result: nil, error_messages: ["multiValidated must include exactly one of the following arguments: (a and b), c."] },
      ]
    },
    {
      name: "Input object validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: { b: 2, c: 3 }) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedInput(input: { a: 1, b: 2, c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { a: 1, b: 2 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { a: 1, c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { c: 3 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedInput(input: { b: 2 }) }", result: nil, error_messages: ["ValidatedInput must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "Resolver validation",
      config: { one_of: [:a, [:b, :c]] },
      cases: [
        { query: "{ validated: validatedResolver(a: 1) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedResolver(b: 2, c: 3) }", result: 5, error_messages: [] },
        { query: "{ validated: validatedResolver(a: 1, b: 2, c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(a: 1, b: 2) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(a: 1, c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(c: 3) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver(b: 2) }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
        { query: "{ validated: validatedResolver }", result: nil, error_messages: ["validatedResolver must include exactly one of the following arguments: a, (b and c)."] },
      ]
    },
    {
      name: "Single arg validation",
      config: { argument: :a, message: "A value must be given, even if it's `null` (not %{value})" },
      cases: [
        { query: "{ validated: validatedInput(input: { a: 1 }) }", result: 1, error_messages: [] },
        { query: "{ validated: validatedInput(input: {}) }", result: nil, error_messages: ["A value must be given, even if it's `null` (not {})"] },
        { query: "{ validated: validatedInput(input: { a: null }) }", result: 0, error_messages: [] },
      ]
    }
  ]

  build_tests(:required, Integer, expectations)
end
