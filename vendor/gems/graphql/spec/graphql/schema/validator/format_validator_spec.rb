# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::FormatValidator do
  include ValidatorHelpers

  expectations = [
    {
      config: { with: /\A[a-z]+\Z/ },
      cases: [
        { query: "{ validated(value: \"abcd\") }", result: "abcd", error_messages: [] },
        { query: "{ validated(value: \"ABC\") }", result: nil, error_messages: ["value is invalid"] },
      ]
    },
    {
      config: { with: /\A[a-z]+\Z/, allow_blank: true },
      cases: [
        { query: "{ validated(value: \"abcd\") }", result: "abcd", error_messages: [] },
        { query: "{ validated(value: \"ABC\") }", result: nil, error_messages: ["value is invalid"] },
        (String.method_defined?(:blank?) ?
          { query: "{ validated(value: \"\") }", result: "", error_messages: [] }
        :
          { query: "{ validated(value: \"\") }", result: nil, error_messages: ["value is invalid"] }
        ),
      ]
    },
    {
      config: { without: /[a-z]/ },
      cases: [
        { query: "{ validated(value: \"abcd\") }", result: nil, error_messages: ["value is invalid"] },
        { query: "{ validated(value: null) }", result: nil, error_messages: ["value is invalid"] },
        { query: "{ validated(value: \"ABC\") }", result: "ABC", error_messages: [] },
      ]
    },
  ]

  build_tests(:format, String, expectations)
end
