# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentTypesExist do
  include StaticValidationHelpers

  let(:query_string) {"
    query getCheese {
      cheese(id: 1) {
        ... on Cheese { source }
        ... on Nothing { whatever }
        ... somethingFields
        ... cheeseFields
        ...cf2
      }
    }

    fragment somethingFields on Something {
      something
    }
    fragment cheeseFields on Cheese {
      fatContent
    }
    fragment cf2 on Chese {
      fatContent
    }
  "}

  it "finds non-existent types on fragments" do
    assert_equal(3, errors.length)
    inline_fragment_error =  {
      "message"=>"No such type Something, so it can't be a fragment condition",
      "locations"=>[{"line"=>12, "column"=>5}],
      "path"=>["fragment somethingFields"],
      "extensions"=>{"code"=>"undefinedType", "typeName"=>"Something"}
    }
    assert_includes(errors, inline_fragment_error, "on inline fragments")
    fragment_def_error = {
      "message"=>"No such type Nothing, so it can't be a fragment condition",
      "locations"=>[{"line"=>5, "column"=>9}],
      "path"=>["query getCheese", "cheese", "... on Nothing"],
      "extensions"=>{"code"=>"undefinedType", "typeName"=>"Nothing"}
    }
    assert_includes(errors, fragment_def_error, "on fragment definitions")
    fragment_def_error = {
      "message"=>"No such type Chese, so it can't be a fragment condition (Did you mean `Cheese`?)",
      "locations"=>[{"line"=>18, "column"=>5}],
      "path"=>["fragment cf2"],
      "extensions"=>{"code"=>"undefinedType", "typeName"=>"Chese"}
    }
    assert_includes(errors, fragment_def_error, "on fragment definitions")
  end
end
