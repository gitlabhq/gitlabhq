# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreUsed do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      name
      ...cheeseFields
      ...undefinedFields
    }
    fragment cheeseFields on Cheese { fatContent }
    fragment unusedFields on Cheese { is, not, used }
  "}

  it "adds errors for unused fragment definitions" do
    assert_includes(errors, {
      "message"=>"Fragment unusedFields was defined, but not used",
      "locations"=>[{"line"=>8, "column"=>5}],
      "path"=>["fragment unusedFields"],
      "extensions"=>{"code"=>"useAndDefineFragment", "fragmentName"=>"unusedFields"}
    })
  end

  it "adds errors for undefined fragment spreads" do
    assert_includes(errors, {
      "message"=>"Fragment undefinedFields was used, but not defined",
      "locations"=>[{"line"=>5, "column"=>7}],
      "path"=>["query getCheese", "... undefinedFields"],
      "extensions"=>{"code"=>"useAndDefineFragment", "fragmentName"=>"undefinedFields"}
    })
  end

  describe "invalid unused fragments" do
    let(:query_string) {"
      query getCheese {
        name
      }
      fragment Invalid on DoesNotExist { fatContent }
    "}

    it "handles them gracefully" do
      assert_includes(errors, {
        "message"=>"No such type DoesNotExist, so it can't be a fragment condition",
        "locations"=>[{"line"=>5, "column"=>7}],
        "path"=>["fragment Invalid"],
        "extensions"=>{"code"=>"undefinedType", "typeName"=>"DoesNotExist"}
      })
    end
  end

  describe "with error limiting" do
    let(:query_string) {"
      query getCheese {
        ...cheeseFields
        ...undefinedFields
      }
      fragment cheeseFields on Cheese { fatContent }
      fragment unusedFields on Cheese { not_used }
      fragment yetMoreUnusedFields on Cheese { must_be_vegan }
    "}

    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 6)
        assert_equal(error_messages,[
          "Field 'not_used' doesn't exist on type 'Cheese'",
          "Field 'must_be_vegan' doesn't exist on type 'Cheese'",
          "Fragment cheeseFields on Cheese can't be spread inside Query",
          "Fragment undefinedFields was used, but not defined",
          "Fragment yetMoreUnusedFields was defined, but not used",
          "Fragment unusedFields was defined, but not used"
        ])
      end
    end

    describe("enabled") do
      let(:args) {
        { max_errors: 5 }
      }

      it "does limit the number of errors" do
        assert_equal(error_messages.length, 5)
        assert_equal(error_messages, [
          "Field 'not_used' doesn't exist on type 'Cheese'",
          "Field 'must_be_vegan' doesn't exist on type 'Cheese'",
          "Fragment cheeseFields on Cheese can't be spread inside Query",
          "Fragment undefinedFields was used, but not defined",
          "Fragment yetMoreUnusedFields was defined, but not used",
        ])
      end
    end
  end
end
