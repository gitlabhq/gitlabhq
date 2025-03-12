# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsAreDefinedOnType do
  include StaticValidationHelpers
  let(:query_string) { "
    query getCheese {
      notDefinedField { name }
      cheese(id: 1) { nonsenseField, flavor ...cheeseFields }
      fromSource(source: COW) { bogusField }
    }

    fragment cheeseFields on Cheese { fatContent, hogwashField }
  "}

  it "finds fields that are requested on types that don't have that field" do
    expected_errors = [
      "Field 'notDefinedField' doesn't exist on type 'Query'",  # from query root
      "Field 'nonsenseField' doesn't exist on type 'Cheese'",   # from another field
      "Field 'bogusField' doesn't exist on type 'Cheese'",      # from a list
      "Field 'hogwashField' doesn't exist on type 'Cheese'",    # from a fragment
    ]
    assert_equal(expected_errors, error_messages)
  end

  describe "on objects" do
    let(:query_string) { "query getStuff { notDefinedField }"}

    it "finds invalid fields" do
      expected_errors = [
        {
          "message"=>"Field 'notDefinedField' doesn't exist on type 'Query'",
          "locations"=>[{"line"=>1, "column"=>18}],
          "path"=>["query getStuff", "notDefinedField"],
          "extensions"=>{"code"=>"undefinedField", "typeName"=>"Query", "fieldName"=>"notDefinedField"}
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe "on interfaces" do
    let(:query_string) { "query getStuff { favoriteEdible { amountThatILikeIt orgin } }"}

    it "finds invalid fields" do
      expected_errors = [
        {
          "message"=>"Field 'amountThatILikeIt' doesn't exist on type 'Edible'",
          "locations"=>[{"line"=>1, "column"=>35}],
          "path"=>["query getStuff", "favoriteEdible", "amountThatILikeIt"],
          "extensions"=>{"code"=>"undefinedField", "typeName"=>"Edible", "fieldName"=>"amountThatILikeIt"}
        },
        {
          "message"=>"Field 'orgin' doesn't exist on type 'Edible' (Did you mean `origin`?)",
          "locations"=>[{"line"=>1, "column"=>53}],
          "path"=>["query getStuff", "favoriteEdible", "orgin"],
          "extensions"=>{"code"=>"undefinedField", "typeName"=>"Edible", "fieldName"=>"orgin"}
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe "on unions" do
    let(:query_string) { "
      query notOnUnion { favoriteEdible { ...dpFields ...dpIndirectFields } }
      fragment dpFields on DairyProduct { source }
      fragment dpIndirectFields on DairyProduct { ... on Cheese { source } }
    "}

    it "doesnt allow selections on unions" do
      expected_errors = [
        {
          "message"=>"Selections can't be made directly on unions (see selections on DairyProduct)",
          "locations"=>[
            {"line"=>3, "column"=>7}
          ],
          "path"=>["fragment dpFields", "source"],
          "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"DairyProduct"}
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe "__typename" do
    describe "on existing unions" do
      let(:query_string) { "
        query { favoriteEdible { ...dpFields } }
        fragment dpFields on DairyProduct { __typename }
      "}

      it "is allowed" do
        assert_equal([], errors)
      end
    end

    describe "on existing objects" do
      let(:query_string) { "
        query { cheese(id: 1) { __typename } }
      "}

      it "is allowed" do
        assert_equal([], errors)
      end
    end
  end

  describe "__schema" do
    describe "on query root" do
      let(:query_string) { "
        query { __schema { queryType { name } } }
      "}

      it "is allowed" do
        assert_equal([], errors)
      end
    end

    describe "on non-query root" do
      let(:query_string) { "
        query { cheese(id: 1) { __schema { queryType { name } } } }
      "}

      it "is not allowed" do
        expected_errors = [
          {
            "message"=>"Field '__schema' doesn't exist on type 'Cheese'",
            "locations"=>[
              {"line"=>2, "column"=>33}
            ],
            "path"=>["query", "cheese", "__schema"],
            "extensions"=>{"code"=>"undefinedField", "typeName"=>"Cheese", "fieldName"=>"__schema"}
          }
        ]
        assert_equal(expected_errors, errors)
      end
    end
  end

  describe "__type" do
    describe "on query root" do
      let(:query_string) { %|
        query { __type(name: "Cheese") { name } }
      |}

      it "is allowed" do
        assert_equal([], errors)
      end
    end

    describe "on non-query root" do
      let(:query_string) { %|
        query { cheese(id: 1) { __type(name: "Cheese") { name } } }
      |}

      it "is not allowed" do
        expected_errors = [
          {
            "message"=>"Field '__type' doesn't exist on type 'Cheese'",
            "locations"=>[
              {"line"=>2, "column"=>33}
            ],
            "path"=>["query", "cheese", "__type"],
            "extensions"=>{"code"=>"undefinedField", "typeName"=>"Cheese", "fieldName"=>"__type"}
          }
        ]
        assert_equal(expected_errors, errors)
      end
    end
  end

end
