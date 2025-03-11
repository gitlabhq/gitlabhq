# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::DirectivesAreDefined do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) {
        id @skip(if: true),
        source @nonsense(if: false)
        ... on Cheese {
          flavor @moreNonsense @moreNonsense
        }
        id2: id @sikp(if: true)
      }
    }
  "}
  describe "non-existent directives" do
    it "makes errors for them" do
      expected = [
        {
          "message"=>"Directive @nonsense is not defined",
          "locations"=>[{"line"=>5, "column"=>16}],
          "path"=>["query getCheese", "okCheese", "source"],
          "extensions"=>{"code"=>"undefinedDirective", "directiveName"=>"nonsense"}
        },
        {
          "message"=>"The directive \"moreNonsense\" can only be used once at this location.",
          "locations"=>[{"line"=>7, "column"=>18}, {"line"=>7, "column"=>32}],
          "path"=>["query getCheese", "okCheese", "... on Cheese", "flavor"],
          "extensions"=>{"code"=>"directiveNotUniqueForLocation", "directiveName"=>"moreNonsense"}
        },
        {
          "message"=>"Directive @moreNonsense is not defined",
          "locations"=>[{"line"=>7, "column"=>18}, {"line"=>7, "column"=>32}],
          "path"=>["query getCheese", "okCheese", "... on Cheese", "flavor"],
          "extensions"=>{"code"=>"undefinedDirective", "directiveName"=>"moreNonsense"}
        },
        {
          "message"=>"Directive @sikp is not defined (Did you mean `skip`?)",
          "locations"=>[{"line"=>9, "column"=>17}],
          "path"=>["query getCheese", "okCheese", "id2"],
          "extensions"=>{"code"=>"undefinedDirective", "directiveName"=>"sikp"}
        }
      ]
      assert_equal(expected, errors)
    end
  end
end
