# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::IntrospectionSystem do
  describe "custom introspection" do
    it "serves custom fields on types" do
      res = Jazz::Schema.execute("{ __schema { isJazzy } }")
      assert_equal true, res["data"]["__schema"]["isJazzy"]
    end

    it "serves overridden fields on types" do
      res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|)
      assert_equal "ENSEMBLE", res["data"]["__type"]["name"]
    end

    it "serves custom entry points" do
      res = Jazz::Schema.execute("{ __classname }", root_value: Set.new)
      assert_equal "Set", res["data"]["__classname"]
    end

    it "calls authorization methods of those types" do
      res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|)
      assert_equal "ENSEMBLE", res["data"]["__type"]["name"]

      unauth_res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|, context: { cant_introspect: true })
      assert_nil unauth_res["data"].fetch("__type")
      assert_equal ["You're not allowed to introspect here"], unauth_res["errors"].map { |e| e["message"] }
    end

    it "serves custom dynamic fields" do
      res = Jazz::Schema.execute("{ nowPlaying { __typename __typenameLength __astNodeClass } }")
      assert_equal "Ensemble", res["data"]["nowPlaying"]["__typename"]
      assert_equal 8, res["data"]["nowPlaying"]["__typenameLength"]
      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["nowPlaying"]["__astNodeClass"]
    end

    it "doesn't affect other schemas" do
      res = Dummy::Schema.execute("{ __schema { isJazzy } }")
      assert_equal 1, res["errors"].length

      res = Dummy::Schema.execute("{ __classname }", root_value: Set.new)
      assert_equal 1, res["errors"].length

      res = Dummy::Schema.execute("{ ensembles { __typenameLength } }")
      assert_equal 1, res["errors"].length
    end

    it "runs the introspection query" do
      res = Jazz::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert res
      query_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "QUERY" }
      ensembles_field = query_type["fields"].find { |f| f["name"] == "ensembles" }
      assert_equal [], ensembles_field["args"]
    end

    it "doesn't include invisible union types based on context" do
      context = { hide_ensemble: true }
      res = Jazz::Schema.execute('{ __type(name: "PerformingAct") { possibleTypes { name } } }', context: context)

      assert_equal 1, res["data"]["__type"]["possibleTypes"].length
      assert_equal "MUSICIAN", res["data"]["__type"]["possibleTypes"].first["name"]
    end

    it "does not include hidden interfaces by membership based on context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].none? { |i| i["name"] == "PRIVATENAMEENTITY" }
    end

    it "includes hidden interfaces by membership based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].any? { |i| i["name"] == "PRIVATENAMEENTITY" }
    end

    it "does not include hidden interfaces by membership based on context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].none? { |i| i["name"] == "INVISIBLENAMEENTITY" }
    end

    it "includes hidden interfaces by membership based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].any? { |i| i["name"] == "INVISIBLENAMEENTITY" }
    end

    it "does not include fields from hidden interfaces by membership based on the context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)

      assert res["data"]["__type"]["fields"].none? { |i| i["name"] == "privateName" }
    end

    it "includes fields from interfaces by membership based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)
      assert res["data"]["__type"]["fields"].any? { |i| i["name"] == "privateName" }
    end

    it "does not include fields from hidden interfaces based on the context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)

      assert res["data"]["__type"]["fields"].none? { |i| i["name"] == "invisibleName" }
    end

    it "includes fields from interfaces based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)
      assert res["data"]["__type"]["fields"].any? { |i| i["name"] == "invisibleName" }
    end

    it "includes fields that are defined locally on the object, even when the interface's implementation is private" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)
      assert res["data"]["__type"]["fields"].any? { |i| i["name"] == "overriddenName" }
    end

    it "includes extra types" do
      res = Jazz::Schema.execute('{ __type(name: "BlogPost") { name } }')
      assert_equal "BLOGPOST", res["data"]["__type"]["name"]
      res2 = Jazz::Schema.execute("{ __schema { types { name } } }")
      names = res2["data"]["__schema"]["types"].map { |t| t["name"] }
      assert_includes names, "BLOGPOST"
    end
  end

  describe "copying the built-ins" do
    module IntrospectionCopyTest
      class Query < GraphQL::Schema::Object
        field :int, Integer, null: false
      end

      class Schema1 < GraphQL::Schema
        query(Query)
      end

      class Schema2 < GraphQL::Schema
        query(Query)
      end
    end

    it "makes copies of built-in types for each schema, so that local modifications don't affect the base classes" do
      refute_equal IntrospectionCopyTest::Schema1.types["__Type"], IntrospectionCopyTest::Schema2.types["__Type"]
    end
  end

  describe "#disable_introspection_entry_points" do
    let(:schema) { Jazz::Schema }

    it "allows the __schema entry point introspection by default" do
      res = schema.execute("{ __schema { types { name } } }")
      assert res

      types = res["data"]["__schema"]["types"]
      refute_empty types
    end

    it "allows the __type entry point introspection by default" do
      res = schema.execute('{ __type(name: "Musician") { name } }')
      assert res

      types = res["data"]["__type"]["name"]
      refute_empty types
    end

    describe "when entry points introspection is disabled" do
      let(:schema) { Jazz::SchemaWithoutIntrospection }

      it "returns error on __schema introspection" do
        res = schema.execute("{ __schema { types { name } } }")
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__schema' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end

      it "returns error on __type introspection" do
        res = schema.execute('{ __type(name: "Musician") { name } }')
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__type' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end
    end

    describe "when the __schema entry point introspection is disabled" do
      let(:schema) { Jazz::SchemaWithoutSchemaIntrospection }

      it "allows the __type entry point introspection" do
        res = schema.execute('{ __type(name: "Musician") { name } }')
        assert res

        types = res["data"]["__type"]["name"]
        refute_empty types
      end

      it "returns error" do
        res = schema.execute("{ __schema { types { name } } }")
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__schema' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end
    end

    describe "when __type entry point introspection is disabled" do
      let(:schema) { Jazz::SchemaWithoutTypeIntrospection }

      it "allows the __schema entry point introspection by default" do
        res = schema.execute("{ __schema { types { name } } }")
        assert res

        types = res["data"]["__schema"]["types"]
        refute_empty types
      end

      it "returns error" do
        res = schema.execute('{ __type(name: "Musician") { name } }')
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__type' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end
    end

    describe "when __type and __schema entry point introspection is disabled" do
      let(:schema) { Jazz::SchemaWithoutSchemaOrTypeIntrospection }

      it "returns error on __schema introspection" do
        res = schema.execute("{ __schema { types { name } } }")
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__schema' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end

      it "returns error on __type introspection" do
        res = schema.execute('{ __type(name: "Musician") { name } }')
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__type' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end
    end
  end

  describe "Dynamically hiding them" do
    class HidingIntrospectionSchema < GraphQL::Schema
      use GraphQL::Schema::Warden if ADD_WARDEN

      module HideIntrospectionByContext
        def visible?(ctx)
          super &&
            if introspection?
              !ctx[:hide_introspection]
            else
              true
            end
        end
      end

      class BaseField < GraphQL::Schema::Field
        include HideIntrospectionByContext
      end

      module CustomIntrospection
        class DynamicFields < GraphQL::Introspection::DynamicFields
          field_class(BaseField)
          field :__typename, String, null: false
        end

        class EntryPoints < GraphQL::Introspection::EntryPoints
          field_class(BaseField)
          field :__type, GraphQL::Introspection::TypeType do
            argument :name, String
          end
        end

        class SchemaType < GraphQL::Introspection::SchemaType
          extend HideIntrospectionByContext
        end
      end

      class Query < GraphQL::Schema::Object
        field :int, Integer, null: false
        def int; 1; end
      end

      query(Query)
      introspection(CustomIntrospection)
    end

    it "can implement visible? to return false for dynamic fields" do
      assert_equal "Query", HidingIntrospectionSchema.execute("{ __typename }")["data"]["__typename"]
      error_res = HidingIntrospectionSchema.execute("{ __typename }", context: { hide_introspection: true })

      assert_equal ["Field '__typename' doesn't exist on type 'Query'"], error_res["errors"].map { |e| e["message" ]}
    end

    it "can implement visible? to return false for entry points" do
      query_str = "{ __type(name: \"Query\") { name } }"
      success_res = HidingIntrospectionSchema.execute(query_str)
      assert_equal "Query", success_res["data"]["__type"]["name"]
      error_res = HidingIntrospectionSchema.execute(query_str, context: { hide_introspection: true })
      assert_equal ["Field '__type' doesn't exist on type 'Query'"], error_res["errors"].map { |e| e["message" ]}
    end

    it "can implement visible? to return false for types" do
      query_str = "{ __schema { queryType { name } } }"
      success_res = HidingIntrospectionSchema.execute(query_str)
      assert_equal "Query", success_res["data"]["__schema"]["queryType"]["name"]
      error_res = HidingIntrospectionSchema.execute(query_str, context: { hide_introspection: true })
      assert_equal ["Field '__schema' doesn't exist on type 'Query'"], error_res["errors"].map { |e| e["message" ]}
    end
  end
end
