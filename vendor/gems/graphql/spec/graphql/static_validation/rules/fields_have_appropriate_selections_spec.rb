# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsHaveAppropriateSelections do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { fatContent, similarCheese(source: YAK) { source } }
      missingFieldsObject: cheese(id: 1)
      missingFieldsInterface: cheese(id: 1) { selfAsEdible }
      illegalSelectionCheese: cheese(id: 1) { id { something, ... someFields } }
      incorrectFragmentSpread: cheese(id: 1) { flavor { ... on String { __typename } } }
    }
  "}

  it "adds errors for selections on scalars" do
    assert_equal(4, errors.length)

    illegal_selection_error = {
      "message"=>"Selections can't be made on scalars (field 'id' returns Int but has selections [\"something\", \"someFields\"])",
      "locations"=>[{"line"=>6, "column"=>47}],
      "path"=>["query getCheese", "illegalSelectionCheese", "id"],
      "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'id'", "typeName"=>"Int"}
    }
    assert_includes(errors, illegal_selection_error, "finds illegal selections on scalars")

    objects_selection_required_error = {
      "message"=>"Field must have selections (field 'cheese' returns Cheese but has no selections. Did you mean 'cheese { ... }'?)",
      "locations"=>[{"line"=>4, "column"=>7}],
      "path"=>["query getCheese", "missingFieldsObject"],
      "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'cheese'", "typeName"=>"Cheese"}
    }
    assert_includes(errors, objects_selection_required_error, "finds objects without selections")

    interfaces_selection_required_error = {
      "message"=>"Field must have selections (field 'selfAsEdible' returns Edible but has no selections. Did you mean 'selfAsEdible { ... }'?)",
      "locations"=>[{"line"=>5, "column"=>47}],
      "path"=>["query getCheese", "missingFieldsInterface", "selfAsEdible"],
      "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'selfAsEdible'", "typeName"=>"Edible"}
    }
    assert_includes(errors, interfaces_selection_required_error, "finds interfaces without selections")

    incorrect_fragment_error = {
      "message"=>"Selections can't be made on scalars (field 'flavor' returns String but has selections [\"... on String { ... }\"])",
      "locations"=>[{"line"=>7, "column"=>48}],
      "path"=>["query getCheese", "incorrectFragmentSpread", "flavor"],
      "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'flavor'", "typeName"=>"String"}
    }
    assert_includes(errors, incorrect_fragment_error, "finds scalar fields with selections")
  end

  describe "anonymous operations" do
    let(:query_string) { "{ }" }
    it "requires selections" do
      assert_equal(1, errors.length)

      selections_required_error = {
        "message"=> "Field must have selections (anonymous query returns Query but has no selections. Did you mean ' { ... }'?)",
        "locations"=>[{"line"=>1, "column"=>1}],
        "path"=>["query"],
        "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"anonymous query", "typeName"=>"Query"}
      }
      assert_includes(errors, selections_required_error)
    end
  end

  describe "selections and inline fragments on scalars" do
    let(:query_string) {"
    {
      cheese(id: 1) {
        fatContent {
          name
          ... on User {
            id
          }
          ... F
        }
      }
    }

    fragment F on Cheese {
      id
    }
    "}
    it "returns an error" do
      expected_err = "Selections can't be made on scalars (field 'fatContent' returns Float but has selections [\"name\", \"... on User { ... }\", \"F\"])"
      assert_includes(errors.map { |e| e["message"] }, expected_err)
    end
  end
end
