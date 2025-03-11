# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::NoDefinitionsArePresent do
  include StaticValidationHelpers
  describe "when schema definitions are present in the query" do
    let(:query_string) {
      <<-GRAPHQL
      {
        cheese(id: 1) { flavor }
      }

      type Thing {
        stuff: Int
      }

      scalar Date
      GRAPHQL
    }

    it "adds an error" do
      assert_equal 1, errors.length
      err = errors[0]
      assert_equal "Query cannot contain schema definitions", err["message"]
      assert_equal [{"line"=>5, "column"=>7}, {"line"=>9, "column"=>7}], err["locations"]
    end
  end

  describe "when schema extensions are present in the query" do
    let(:query_string) {
      <<-GRAPHQL
      {
        cheese(id: 1) { flavor }
      }

      extend schema {
        subscription: Query
      }

      extend scalar TracingScalar @deprecated
      extend type Dairy @deprecated
      extend interface Edible @deprecated
      extend union Beverage @deprecated
      extend enum DairyAnimal @deprecated
      extend input ResourceOrderType @deprecated
      GRAPHQL
    }

    it "adds an error" do
      assert_equal 1, errors.length
      err = errors[0]
      assert_equal "Query cannot contain schema definitions", err["message"]
      assert_equal [{"line"=>5, "column"=>7},
        {"line"=>9, "column"=>7},
        {"line"=>10, "column"=>7},
        {"line"=>11, "column"=>7},
        {"line"=>12, "column"=>7},
        {"line"=>13, "column"=>7},
        {"line"=>14, "column"=>7}], err["locations"]
    end
  end
end
