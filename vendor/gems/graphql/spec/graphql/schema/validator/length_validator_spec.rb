# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::LengthValidator do
  include ValidatorHelpers

  it "allows blank and null" do
    schema = build_schema(String, {length: { minimum: 5 }, allow_blank: true})

    blank_string = ValidatorHelpers::BlankString.new("")
    assert blank_string.blank?
    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: blank_string })
    assert_equal "", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: nil })
    refute result.key?("data")
    assert_equal ["Variable $str of type String! was provided invalid value"],  result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 5 }, allow_null: true, allow_blank: false})
    result = schema.execute("{ validated(value: null) }")
    assert_nil result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: blank_string })
    assert_nil result["data"].fetch("validated")
    # This error message is weird, but it can be fixed by removing `minimum: 5`, which causes a redundant error message:
    assert_equal ["value is too short (minimum is 5), value can't be blank"], result["errors"].map { |e| e["message"] }

    # This string doesn't respond to blank:
    non_blank_string = ValidatorHelpers::NonBlankString.new("")
    refute non_blank_string.respond_to?(:blank?), "NonBlankString doesn't have a blank? method"
    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: non_blank_string })
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "validates minimum length" do
    schema = build_schema(String, {length: { minimum: 5 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "validates maximum length" do
    schema = build_schema(String, {length: { maximum: 8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too long (maximum is 8)"], result["errors"].map { |e| e["message"] }
  end

  it "rejects blank, even when within the maximum" do
    schema = build_schema(String, {length: { maximum: 8 }, allow_blank: false })
    blank_string = ValidatorHelpers::BlankString.new("")
    result = schema.execute("query($str: String!) { validated(value: $str) }", variables: { str: blank_string })
    assert_nil result["data"].fetch("validated")
    assert_equal ["value can't be blank"], result["errors"].map { |e| e["message"] }
  end

  it "validates within length" do
    schema = build_schema(String, {length: { within: 5..8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is too long (maximum is 8)"], result["errors"].map { |e| e["message"] }
  end

  it "validates length is" do
    schema = build_schema(String, {length: { is: 8 }})
    result = schema.execute("{ validated(value: \"is-valid\") }")
    assert_equal "is-valid", result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("{ validated(value: \"nono\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is the wrong length (should be 8)"], result["errors"].map { |e| e["message"] }

    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["value is the wrong length (should be 8)"], result["errors"].map { |e| e["message"] }
  end

  it "applies custom messages" do
    schema = build_schema(String, {length: { is: 8, wrong_length: "Instead, make %{validated} have length %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length 8"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 50, too_short: "Instead, make %{validated} have length at least %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length at least 50"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { maximum: 5, too_long: "Instead, make %{validated} have length less than %{count}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["Instead, make value have length less than 5"], result["errors"].map { |e| e["message"] }

    schema = build_schema(String, {length: { minimum: 50, message: "NO, BAD! %{validated} %{count} %{value}" }})
    result = schema.execute("{ validated(value: \"is-invalid\") }")
    assert_nil result["data"].fetch("validated")
    assert_equal ["NO, BAD! value 50 \"is-invalid\""], result["errors"].map { |e| e["message"] }
  end

  list_expectations = [
    {
      config: { minimum: 3 },
      cases: [
        { query: "{ validated(value: [1, 2, 3, 4]) }", result: [1, 2, 3, 4], error_messages: [] },
        { query: "{ validated(value: [1, 2]) }", result: nil, error_messages: ["value is too short (minimum is 3)"] },
      ]
    },
    {
      config: { maximum: 3 },
      cases: [
        { query: "{ validated(value: [1, 2]) }", result: [1, 2], error_messages: [] },
        { query: "{ validated(value: [1, 2, 3, 4]) }", result: nil, error_messages: ["value is too long (maximum is 3)"] },
      ]
    },
    {
      config: { is: 3 },
      cases: [
        { query: "{ validated(value: [1, 2, 3]) }", result: [1, 2, 3], error_messages: [] },
        { query: "{ validated(value: [1, 2]) }", result: nil, error_messages: ["value is the wrong length (should be 3)"] },
      ]
    },
  ]

  build_tests(:length, [Integer], list_expectations)
end
