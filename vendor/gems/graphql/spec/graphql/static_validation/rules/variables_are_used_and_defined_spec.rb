# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreUsedAndDefined do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
      $usedVar: Int!,
      $usedInnerVar: [DairyAnimal!]!,
      $usedInlineFragmentVar: Int!,
      $usedFragmentVar: Int!,
      $notUsedVar: Int!,
    ) {
      c1: cheese(id: $usedVar) {
        __typename
      }
      ... on Query {
        c2: cheese(id: $usedInlineFragmentVar) {
          similarCheese(source: $usedInnerVar) { __typename }
        }

      }

      c3: cheese(id: $undefinedVar) { __typename }

      ... outerCheeseFields
    }

    fragment outerCheeseFields on Query {
      ... innerCheeseFields
    }

    fragment innerCheeseFields on Query {
      c4: cheese(id: $undefinedFragmentVar) { __typename }
      c5: cheese(id: $usedFragmentVar) { __typename }
    }
  '}

  describe "variables which are used-but-not-defined or defined-but-not-used" do
    it "finds the variables" do
      expected = [
        {
          "message"=>"Variable $notUsedVar is declared by getCheese but not used",
          "locations"=>[{"line"=>2, "column"=>5}],
          "path"=>["query getCheese"],
          "extensions"=>{"code"=>"variableNotUsed", "variableName"=>"notUsedVar"}
        },
        {
          "message"=>"Variable $undefinedVar is used by getCheese but not declared",
          "locations"=>[{"line"=>19, "column"=>22}],
          "path"=>["query getCheese", "c3", "id"],
          "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undefinedVar"}
        },
        {
          "message"=>"Variable $undefinedFragmentVar is used by innerCheeseFields but not declared",
          "locations"=>[{"line"=>29, "column"=>22}],
          "path"=>["fragment innerCheeseFields", "c4", "id"],
          "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undefinedFragmentVar"}
        },
      ]

      assert_equal(expected, errors)
    end

    describe "with an anonymous query" do
      let(:query_string) do
        <<-GRAPHQL
        query($notUsedVar: Int!) {
          c1: cheese(id: $undeclared) {
            __typename
          }
        }
        GRAPHQL
      end

      it "shows 'anonymous query' in the message" do
        expected = [
          {
            "message"=>"Variable $notUsedVar is declared by anonymous query but not used",
            "locations"=>[{"line"=>1, "column"=>9}],
            "path"=>["query"],
            "extensions"=>{"code"=>"variableNotUsed", "variableName"=>"notUsedVar"}
          },
          {
            "message"=>"Variable $undeclared is used by anonymous query but not declared",
            "locations"=>[{"line"=>2, "column"=>26}],
            "path"=>["query", "c1", "id"],
            "extensions"=>{"code"=>"variableNotDefined", "variableName"=>"undeclared"}
          }
        ]
        assert_equal(expected, errors)
      end
    end
  end

  describe "usages in directives on fragment spreads" do
    let(:query_string) {
      <<-GRAPHQL
      query($f: Boolean!){
        ...F @include(if: $f)
      }
      fragment F on Query {
        __typename
      }
      GRAPHQL
    }

    it "finds usages" do
      assert_equal([], errors)
    end
  end

  describe "with error limiting" do
    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 3)
        assert_equal(error_messages, [
          "Variable $notUsedVar is declared by getCheese but not used",
          "Variable $undefinedVar is used by getCheese but not declared",
          "Variable $undefinedFragmentVar is used by innerCheeseFields but not declared"
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
          "Variable $notUsedVar is declared by getCheese but not used"
        ])
      end
    end
  end
end
