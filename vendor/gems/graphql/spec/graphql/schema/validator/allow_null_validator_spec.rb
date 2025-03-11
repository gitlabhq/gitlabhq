# frozen_string_literal: true
require "spec_helper"
require_relative "./validator_helpers"

describe GraphQL::Schema::Validator::AllowNullValidator do
  include ValidatorHelpers

  it "allows nil when permitted" do
    schema = build_schema(String, {length: { minimum: 5 }, allow_null: true})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    refute result.key?("errors")
  end

  it "rejects null by default" do
    schema = build_schema(String, {length: { minimum: 5 }})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    assert_equal ["value is too short (minimum is 5)"], result["errors"].map { |e| e["message"] }
  end

  it "can be used standalone" do
    schema = build_schema(String, { allow_null: false })
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    assert_equal ["value can't be null"], result["errors"].map { |e| e["message"] }
  end

  it "allows nil when no validations are configured" do
    schema = build_schema(String, {})
    result = schema.execute("query($str: String) { validated(value: $str) }", variables: { str: nil })
    assert_nil result["data"]["validated"]
    refute result.key?("errors")

    result = schema.execute("query { validated }")
    assert_nil result["data"]["validated"]
    refute result.key?("errors")
  end
end
