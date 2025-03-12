# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentSpreadsArePossible do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) {
        ... milkFields
        ... cheeseFields
        ... on Milk { fatContent }
        ... on AnimalProduct { source }
        ... on DairyProduct {
          ... on Cheese { fatContent }
          ... on Edible { fatContent }
        }
      }
    }

    fragment milkFields on Milk { fatContent }
    fragment cheeseFields on Cheese {
      fatContent
      ... milkFields
    }
  |}

  it "doesnt allow spreads where they'll never apply" do
    # TODO: more negative, abstract examples here, add stuff to the schema
    expected = [
      {
        "message"=>"Fragment on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>6, "column"=>9}],
        "path"=>["query getCheese", "cheese", "... on Milk"],
        "extensions"=>{"code"=>"cannotSpreadFragment", "typeName"=>"Milk", "fragmentName"=>"unknown", "parentName"=>"Cheese"}
      },
      {
        "message"=>"Fragment milkFields on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>4, "column"=>9}],
        "path"=>["query getCheese", "cheese", "... milkFields"],
        "extensions"=>{"code"=>"cannotSpreadFragment", "typeName"=>"Milk", "fragmentName"=>" milkFields", "parentName"=>"Cheese"}
      },
      {
        "message"=>"Fragment milkFields on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>18, "column"=>7}],
        "path"=>["fragment cheeseFields", "... milkFields"],
        "extensions"=>{"code"=>"cannotSpreadFragment", "typeName"=>"Milk", "fragmentName"=>" milkFields", "parentName"=>"Cheese"}
      }
    ]
    assert_equal(expected, errors)
  end
end
