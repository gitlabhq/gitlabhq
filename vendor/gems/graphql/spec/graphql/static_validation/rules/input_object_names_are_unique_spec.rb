# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::InputObjectNamesAreUnique do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      validInputObjectName: searchDairy(product: [{source: YAK}]) { __typename }
      duplicateInputObjectNames: searchDairy(product: [{source: YAK, source: YAK}]) { __typename }
    }
  |}

  describe "when queries contain duplicate input fields" do
    duplicate_input_field_error =  {
      "message" => 'There can be only one input field named "source"',
      "locations"=>[{ "line" => 4, "column" => 57 }, { "line" => 4, "column" => 70 }],
      "path" => ["query getCheese", "duplicateInputObjectNames", "product", 0],
      "extensions" => { "code" => "inputFieldNotUnique", "name" => "source" }
    }

    it "returns errors in the response" do
      assert_includes(errors, duplicate_input_field_error)
    end
  end

  describe "with error limiting" do
    let(:query_string) {%|
      query getCheese {
        validInputObjectName: searchDairy(product: [{source: YAK}]) { __typename }
        duplicateInputObjectNames: searchDairy(product: [{source: YAK, source: YAK}]) { __typename }
        moreDuplicateInputObjectNames: searchDairy(product: [{fatContent: YAK, fatContent: YAK, source: COW}]) { __typename }
      }
    |}

    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 3)
        assert_equal(error_messages, [
          "There can be only one input field named \"source\"",
          "There can be only one input field named \"fatContent\"",
          "Argument 'fatContent' on InputObject 'DairyProductInput' has an invalid value (YAK). Expected type 'Float'."
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
          "There can be only one input field named \"source\"",
        ])
      end
    end
  end
end
