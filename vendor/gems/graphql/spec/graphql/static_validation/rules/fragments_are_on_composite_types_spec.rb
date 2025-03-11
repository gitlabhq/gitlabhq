# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreOnCompositeTypes do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) {
        ... on Cheese {
          source
          ... on Boolean {
            something
          }
        }
        ... intFields
        ... on DairyProduct {
          ... on Cheese {
            flavor
          }
        }
        ... on DairyProductInput {
          something
        }
      }
    }

    fragment intFields on Int {
      something
    }
  |}

  it "requires Object/Union/Interface fragment types" do
    expected = [
      {
        "message"=>"Invalid fragment on type Boolean (must be Union, Interface or Object)",
        "locations"=>[{"line"=>6, "column"=>11}],
        "path"=>["query getCheese", "cheese", "... on Cheese", "... on Boolean"],
        "extensions"=>{"code"=>"fragmentOnNonCompositeType", "typeName"=>"Boolean"}
      },
      {
        "message"=>"Invalid fragment on type DairyProductInput (must be Union, Interface or Object)",
        "locations"=>[{"line"=>16, "column"=>9}],
        "path"=>["query getCheese", "cheese", "... on DairyProductInput"],
        "extensions"=>{"code"=>"fragmentOnNonCompositeType", "typeName"=>"DairyProductInput"}
      },
      {
        "message"=>"Invalid fragment on type Int (must be Union, Interface or Object)",
        "locations"=>[{"line"=>22, "column"=>5}],
        "path"=>["fragment intFields"],
        "extensions"=>{"code"=>"fragmentOnNonCompositeType", "typeName"=>"Int"}
      },
    ]
    assert_equal(expected, errors)
  end
end
