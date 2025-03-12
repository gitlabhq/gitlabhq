# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Directive" do
  let(:variables) { {"t" => true, "f" => false} }
  let(:result) { Dummy::Schema.execute(query_string, variables: variables) }
  describe "on fields" do
    let(:query_string) { %|query directives($t: Boolean!, $f: Boolean!) {
      cheese(id: 1) {
        # plain fields:
        skipFlavor: flavor @skip(if: true)
        dontSkipFlavor: flavor @skip(if: false)
        dontSkipDontIncludeFlavor: flavor @skip(if: false), @include(if: false)
        skipAndInclude: flavor @skip(if: true), @include(if: true)
        includeFlavor: flavor @include(if: $t)
        dontIncludeFlavor: flavor @include(if: $f)
        # fields in fragments
        ... includeIdField
        ... dontIncludeIdField
        ... skipIdField
        ... dontSkipIdField
        }
      }
      fragment includeIdField on Cheese { includeId: id @include(if: true) }
      fragment dontIncludeIdField on Cheese { dontIncludeId: id @include(if: false) }
      fragment skipIdField on Cheese { skipId: id @skip(if: true) }
      fragment dontSkipIdField on Cheese { dontSkipId: id @skip(if: false) }
    |
    }

    describe "child fields" do
      let(:query_string) { <<-GRAPHQL
      {
        __type(name: """
        Cheese
        """) {
          fields { name }
          fields @skip(if: true) { isDeprecated }
        }
      }
      GRAPHQL
      }

      it "skips child fields too" do
        first_field = result["data"]["__type"]["fields"].first
        assert first_field.key?("name")
        assert !first_field.key?("isDeprecated")
      end
    end

    describe "when directive uses argument with default value" do
      describe "with false" do
        let(:query_string) { <<-GRAPHQL
          query($f: Boolean = false) {
            cheese(id: 1) {
              dontIncludeFlavor: flavor @include(if: $f)
              dontSkipFlavor: flavor @skip(if: $f)
            }
          }
        GRAPHQL
        }

        it "is not included" do
          assert !result["data"]["cheese"].key?("dontIncludeFlavor")
        end

        it "is not skipped" do
          assert result["data"]["cheese"].key?("dontSkipFlavor")
        end
      end

      describe "with true" do
        let(:query_string) { <<-GRAPHQL
          query($t: Boolean = true) {
            cheese(id: 1) {
              includeFlavor: flavor @include(if: $t)
              skipFlavor: flavor @skip(if: $t)
            }
          }
        GRAPHQL
        }

        it "is included" do
          assert result["data"]["cheese"].key?("includeFlavor")
        end

        it "is skipped" do
          assert !result["data"]["cheese"].key?("skipFlavor")
        end
      end
    end

    it "intercepts fields" do
      expected = { "data" =>{
        "cheese" => {
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
          "includeId" => 1,
          "dontSkipId" => 1,
        },
      }}
      assert_equal(expected, result)
    end
  end
  describe "on fragments spreads and inline fragments" do
    let(:query_string) { %|query directives {
      cheese(id: 1) {
        ... skipFlavorField @skip(if: true)
        ... dontSkipFlavorField @skip(if: false)
        ... includeFlavorField @include(if: true)
        ... dontIncludeFlavorField @include(if: false)


        ... on Cheese @skip(if: true) { skipInlineId: id }
        ... on Cheese @skip(if: false) { dontSkipInlineId: id }
        ... on Cheese @include(if: true) { includeInlineId: id }
        ... on Cheese @include(if: false) { dontIncludeInlineId: id }
        ... @skip(if: true) { skipNoType: id }
        ... @skip(if: false) { dontSkipNoType: id }
        }
      }
      fragment includeFlavorField on Cheese { includeFlavor: flavor  }
      fragment dontIncludeFlavorField on Cheese { dontIncludeFlavor: flavor  }
      fragment skipFlavorField on Cheese { skipFlavor: flavor  }
      fragment dontSkipFlavorField on Cheese { dontSkipFlavor: flavor }
    |}

    it "intercepts fragment spreads" do
      expected = { "data" => {
        "cheese" => {
          "dontSkipFlavor" => "Brie",
          "includeFlavor" => "Brie",
          "dontSkipInlineId" => 1,
          "includeInlineId" => 1,
          "dontSkipNoType" => 1,
        },
      }}
      assert_equal(expected, result)
    end
  end
  describe "merging @skip and @include" do
    let(:field_included?) { r = result["data"]["cheese"]; r.has_key?('flavor') && r.has_key?('withVariables') }
    let(:skip?) { false }
    let(:include?) { true }
    let(:variables) { {"skip" => skip?, "include" => include?} }
    let(:query_string) {"
      query getCheese ($include: Boolean!, $skip: Boolean!) {
        cheese(id: 1) {
          flavor @include(if: #{include?}) @skip(if: #{skip?}),
          withVariables: flavor @include(if: $include) @skip(if: $skip)
        }
      }
    "}
    # behavior as defined in
    # https://github.com/facebook/graphql/blob/master/spec/Section%203%20--%20Type%20System.md#include
    describe "when @skip=false and @include=true" do
      let(:skip?) { false }
      let(:include?) { true }
      it "is included" do assert field_included? end
    end
    describe "when @skip=false and @include=false" do
      let(:skip?) { false }
      let(:include?) { false }
      it "is not included" do assert !field_included? end
    end
    describe "when @skip=true and @include=true" do
      let(:skip?) { true }
      let(:include?) { true }
      it "is not included" do assert !field_included? end
    end
    describe "when @skip=true and @include=false" do
      let(:skip?) { true }
      let(:include?) { false }
      it "is not included" do assert !field_included? end
    end
    describe "when evaluating skip on query selection and fragment" do
      describe "with @skip" do
        let(:query_string) {"
          query getCheese ($skip: Boolean!) {
            cheese(id: 1) {
              flavor,
              withVariables: flavor,
              ...F0
            }
          }
          fragment F0 on Cheese {
            flavor @skip(if: #{skip?})
            withVariables: flavor @skip(if: $skip)
          }
        "}
        describe "and @skip=false" do
          let(:skip?) { false }
          it "is included" do assert field_included? end
        end
        describe "and @skip=true" do
          let(:skip?) { true }
          it "is included" do assert field_included? end
        end
      end
    end
    describe "when evaluating conflicting @skip and @include on query selection and fragment" do
      let(:query_string) {"
        query getCheese ($include: Boolean!, $skip: Boolean!) {
          cheese(id: 1) {
            ... on Cheese @include(if: #{include?}) {
              flavor
            }
            withVariables: flavor @include(if: $include),
            ...F0
          }
        }
        fragment F0 on Cheese {
          flavor @skip(if: #{skip?}),
          withVariables: flavor @skip(if: $skip)
        }
      "}
      describe "when @skip=false and @include=true" do
        let(:skip?) { false }
        let(:include?) { true }
        it "is included" do assert field_included? end
      end
      describe "when @skip=false and @include=false" do
        let(:skip?) { false }
        let(:include?) { false }
        it "is included" do assert field_included? end
      end
      describe "when @skip=true and @include=true" do
        let(:skip?) { true }
        let(:include?) { true }
        it "is included" do assert field_included? end
      end
      describe "when @skip=true and @include=false" do
        let(:skip?) { true }
        let(:include?) { false }
        it "is not included" do
          assert !field_included?
        end
      end
    end

    describe "when handling multiple fields at the same level" do
      describe "when at least one occurrence would be included" do
        let(:query_string) {"
          query getCheese ($include: Boolean!, $skip: Boolean!) {
            cheese(id: 1) {
              ... on Cheese {
                flavor
              }
              flavor @include(if: #{include?}),
              flavor @skip(if: #{skip?}),
              withVariables: flavor,
              withVariables: flavor @include(if: $include),
              withVariables: flavor @skip(if: $skip)
            }
          }
        "}
        let(:skip?) { true }
        let(:include?) { false }
        it "is included" do assert field_included? end
      end
      describe "when no occurrence would be included" do
        let(:query_string) {"
          query getCheese ($include: Boolean!, $skip: Boolean!) {
            cheese(id: 1) {
              flavor @include(if: #{include?}),
              flavor @skip(if: #{skip?}),
              withVariables: flavor @include(if: $include),
              withVariables: flavor @skip(if: $skip)
            }
          }
        "}
        let(:skip?) { true }
        let(:include?) { false }
        it "is not included" do assert !field_included? end
      end
    end
  end
end
