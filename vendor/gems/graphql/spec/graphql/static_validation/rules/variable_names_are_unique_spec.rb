# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableNamesAreUnique do
  include StaticValidationHelpers

  let(:query_string) { <<-GRAPHQL
  query GetStuff($var1: Int!, $var2: Int!, $var1: Int!, $var2: Int!, $var3: Int!) {
    c1: cheese(id: $var1) { flavor }
    c2: cheese(id: $var2) { flavor }
    c3: cheese(id: $var3) { flavor }
  }
  GRAPHQL
  }

  it "finds duplicate variable names" do
    assert_equal 2, errors.size

    last_err = errors.last
    assert_equal 'There can only be one variable named "var2"', last_err["message"]
    assert_equal 2, last_err["locations"].size
  end

  describe "with error limiting" do
    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 2)
        assert_equal(error_messages, [
          "There can only be one variable named \"var1\"",
          "There can only be one variable named \"var2\""
        ])
      end
    end

    describe("enabled") do
      let(:args) {
        { max_errors: 1 }
      }

      it "does limit the number of errors" do
        assert_equal(error_messages.length, 1)
        assert_equal(error_messages, [
          "There can only be one variable named \"var1\"",
        ])
      end
    end
  end
end
