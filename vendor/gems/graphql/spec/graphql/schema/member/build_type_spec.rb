# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::BuildType do
  describe ".parse_type" do
    it "resolves a string type from a string" do
      assert_equal GraphQL::Types::String, GraphQL::Schema::Member::BuildType.parse_type("String", null: true)
    end

    it "resolves an integer type from a string" do
      assert_equal GraphQL::Types::Int, GraphQL::Schema::Member::BuildType.parse_type("Integer", null: true)
    end

    it "resolves a float type from a string" do
      assert_equal GraphQL::Types::Float, GraphQL::Schema::Member::BuildType.parse_type("Float", null: true)
    end

    it "resolves a boolean type from a string" do
      assert_equal GraphQL::Types::Boolean, GraphQL::Schema::Member::BuildType.parse_type("Boolean", null: true)
    end

    it "resolves an interface type from a string" do
      assert_equal Jazz::BaseInterface, GraphQL::Schema::Member::BuildType.parse_type("Jazz::BaseInterface", null: true)
    end

    it "resolves an object type from a class" do
      assert_equal Jazz::BaseObject, GraphQL::Schema::Member::BuildType.parse_type(Jazz::BaseObject, null: true)
    end

    it "resolves an object type from a string" do
      assert_equal Jazz::BaseObject, GraphQL::Schema::Member::BuildType.parse_type("Jazz::BaseObject", null: true)
    end

    it "resolves a nested object type from a string" do
      assert_equal Jazz::Introspection::NestedType, GraphQL::Schema::Member::BuildType.parse_type("Jazz::Introspection::NestedType", null: true)
    end

    it "resolves a deeply nested object type from a string" do
      assert_equal Jazz::Introspection::NestedType::DeeplyNestedType, GraphQL::Schema::Member::BuildType.parse_type("Jazz::Introspection::NestedType::DeeplyNestedType", null: true)
    end

    it "resolves a list type from an array of classes" do
      assert_instance_of GraphQL::Schema::List, GraphQL::Schema::Member::BuildType.parse_type([Jazz::BaseObject], null: true)
    end

    it "resolves a list type from an array of strings" do
      assert_instance_of GraphQL::Schema::List, GraphQL::Schema::Member::BuildType.parse_type(["Jazz::BaseObject"], null: true)
    end
  end

  describe ".to_type_name" do
    it "works with lists and non-nulls" do
      t = Class.new(GraphQL::Schema::Object) do
        graphql_name "T"
      end

      req_t = GraphQL::Schema::NonNull.new(t)
      list_req_t = GraphQL::Schema::List.new(req_t)

      assert_equal "T", GraphQL::Schema::Member::BuildType.to_type_name(list_req_t)
    end
  end

  describe ".camelize" do
    it "keeps a string that does not contain underscore intact" do
      s = "graphQL"
      assert_equal s, GraphQL::Schema::Member::BuildType.camelize(s)
    end

    it "keeps an underscore itself intact" do
      s = "_"
      assert_equal s, GraphQL::Schema::Member::BuildType.camelize(s)
    end

    it "converts a string that contains underscore into a camelized one" do
      s = "graph_ql"
      assert_equal "graphQl", GraphQL::Schema::Member::BuildType.camelize(s)
    end
  end
end
