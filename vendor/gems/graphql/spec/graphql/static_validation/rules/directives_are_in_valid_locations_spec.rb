# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::DirectivesAreInValidLocations do
  include StaticValidationHelpers

  describe "invalid directive locations" do
    let(:query_string) {"
      query getCheese @skip(if: true) {
        okCheese: cheese(id: 1) {
          id @skip(if: true),
          source
          ... on Cheese @skip(if: true) {
            flavor
            ... whatever
          }
        }
      }
  
      fragment whatever on Cheese @skip(if: true) {
        id
      }
    "}

    it "makes errors for them" do
      expected = [
        {
          "message"=> "'@skip' can't be applied to queries (allowed: fields, fragment spreads, inline fragments)",
          "locations"=>[{"line"=>2, "column"=>23}],
          "path"=>["query getCheese"],
          "extensions"=>{"code"=>"directiveCannotBeApplied", "targetName"=>"queries", "name"=>"skip"}
        },
        {
          "message"=>"'@skip' can't be applied to fragment definitions (allowed: fields, fragment spreads, inline fragments)",
          "locations"=>[{"line"=>13, "column"=>35}],
           "path"=>["fragment whatever"],
           "extensions"=>{"code"=>"directiveCannotBeApplied", "targetName"=>"fragment definitions", "name"=>"skip"}
        },
      ]
      assert_equal(expected, errors)
    end
  end

  describe "valid directive locations" do
    let(:query_string) {"
      query getCheese($id: Int! @directiveForVariableDefinition) {
        cheese(id: $id) {
          id
        }
      }
    "}

    it "does not make errors for them" do
      expected = []
      assert_equal(expected, errors)
    end
  end
end
