# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe ".eql?" do
    let(:document1) { GraphQL.parse(query_string1) }
    let(:document2) { GraphQL.parse(query_string2) }

    describe "large identical document" do
      let(:query_string1) {%|
        query getStuff($someVar: Int = 1, $anotherVar: [String!], $skipNested: Boolean! = false) @skip(if: false) {
          myField: someField(someArg: $someVar, ok: 1.4) @skip(if: $anotherVar) @thing(or: "Whatever")
          anotherField(someArg: [1, 2, 3]) {
            nestedField
            ...moreNestedFields @skip(if: $skipNested)
          }
          ... on OtherType @include(unless: false) {
            field(arg: [{ key: "value", anotherKey: 0.9, anotherAnotherKey: WHATEVER }])
            anotherField
          }
          ... {
            id
          }
        }

        fragment moreNestedFields on NestedType @or(something: "ok") {
          anotherNestedField
        }
      |}
      let(:query_string2) { query_string1 }

      it "should be equal" do
        assert document1 == document2
        assert document2 == document1
      end
    end

    describe "different operations" do
      let(:query_string1) { "query { field }" }
      let(:query_string2) { "mutation { setField }" }

      it "should not be equal" do
        refute document1 == document2
        refute document2 == document1
      end
    end

    describe "different query fields" do
      let(:query_string1) { "query { foo }" }
      let(:query_string2) { "query { bar }" }

      it "should not be equal" do
        refute document1 == document2
        refute document2 == document1
      end
    end

    describe "different schemas" do
      let(:query_string1) {%|
        schema {
          query: Query
        }

        type Query {
          field: String!
        }
      |}
      let(:query_string2) {%|
        schema {
          query: Query
        }

        type Query {
          field: Int!
        }
      |}

      it "should not be equal" do
        refute document1.eql?(document2)
        refute document2.eql?(document1)
      end
    end
  end
end
