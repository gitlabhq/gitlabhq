# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreInputTypes do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
      $id:        Int = 1,
      $str:       [String!],
      $interface: AnimalProduct!,
      $object:    Milk = 1,
      $objects:   [Cheese]!,
      $unknownType: Nonsense,
      $misspelled: Bolean,
    ) {
      cheese(id: $id) { source }
      __type(name: $str) { name }
    }
  '}

  it "finds variables whose types are invalid" do
    assert_includes(errors, {
      "message"=>"AnimalProduct isn't a valid input type (on $interface)",
      "locations"=>[{"line"=>5, "column"=>7}],
      "path"=>["query getCheese"],
      "extensions"=> {"code"=>"variableRequiresValidType", "typeName"=>"AnimalProduct", "variableName"=>"interface"}
    })

    assert_includes(errors, {
      "message"=>"Milk isn't a valid input type (on $object)",
      "locations"=>[{"line"=>6, "column"=>7}],
      "path"=>["query getCheese"],
      "extensions"=>{"code"=>"variableRequiresValidType", "typeName"=>"Milk", "variableName"=>"object"}
    })

    assert_includes(errors, {
      "message"=>"Cheese isn't a valid input type (on $objects)",
      "locations"=>[{"line"=>7, "column"=>7}],
      "path"=>["query getCheese"],
      "extensions"=>{"code"=>"variableRequiresValidType", "typeName"=>"Cheese", "variableName"=>"objects"}
    })

    assert_includes(errors, {
      "message"=>"Nonsense isn't a defined input type (on $unknownType)",
      "locations"=>[{"line"=>8, "column"=>7}],
      "path"=>["query getCheese"],
      "extensions"=>{"code"=>"variableRequiresValidType", "typeName"=>"Nonsense", "variableName"=>"unknownType"}
    })

    assert_includes(errors, {
      "message"=>"Bolean isn't a defined input type (on $misspelled) (Did you mean `Boolean`?)",
      "locations"=>[{"line"=>9, "column"=>7}],
      "path"=>["query getCheese"],
      "extensions"=>{"code"=>"variableRequiresValidType", "typeName"=>"Bolean", "variableName"=>"misspelled"}
    })
  end

  describe "typos" do
    it "returns a client error" do

      res = schema.execute <<-GRAPHQL
        query GetCheese($id: IDX) {
          cheese(id: $id) { flavor }
        }
      GRAPHQL

      assert_equal false, res.key?("data")
      assert_equal 1, res["errors"].length
      assert_equal "IDX isn't a defined input type (on $id) (Did you mean `ID`?)", res["errors"][0]["message"]
    end

    it "returns a client error when there are directives" do
      res = schema.execute <<-GRAPHQL
        query GetCheese($msg: IDX) {
          cheese(id: $id) @skip(if: true) { flavor }
        }
      GRAPHQL

      assert_equal false, res.key?("data")
      assert_equal 3, res["errors"].length
      assert_equal "IDX isn't a defined input type (on $msg) (Did you mean `ID`?)", res["errors"][0]["message"]
      assert_equal "Variable $msg is declared by GetCheese but not used", res["errors"][1]["message"]
      assert_equal "Variable $id is used by GetCheese but not declared", res["errors"][2]["message"]
    end
  end
end
