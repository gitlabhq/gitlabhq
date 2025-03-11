# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Interface do
  let(:interface) { Jazz::GloballyIdentifiableType }

  describe ".path" do
    it "is the name" do
      assert_equal "GloballyIdentifiable", interface.path
    end
  end

  describe "type info" do
    it "tells its type info" do
      assert_equal "GloballyIdentifiable", interface.graphql_name
      assert_equal 2, interface.fields.size
    end

    module NewInterface1
      include Jazz::GloballyIdentifiableType
    end

    module NewInterface2
      include Jazz::GloballyIdentifiableType
      def new_method
      end
    end

    it "can override methods" do
      new_object_1 = Class.new(GraphQL::Schema::Object) do
        implements NewInterface1
      end

      assert_equal 2, new_object_1.fields.size
      assert new_object_1.method_defined?(:id)

      new_object_2 = Class.new(GraphQL::Schema::Object) do
        graphql_name "XYZ"
        implements NewInterface2
        field :id, "ID", null: false, description: "The ID !!!!!"
      end

      assert_equal 2, new_object_2.fields.size
      # It got the new method
      assert new_object_2.method_defined?(:new_method)
      # And the inherited method
      assert new_object_2.method_defined?(:id)

      # It gets an overridden description:
      assert_equal "The ID !!!!!", new_object_2.fields["id"].description
    end
  end

  describe "using `include`" do
    it "raises" do
      err = assert_raises RuntimeError do
        Class.new(GraphQL::Schema::Object) do
          include(Jazz::GloballyIdentifiableType)
        end
      end

      assert_includes err.message, "implements(Jazz::GloballyIdentifiableType)"
    end
  end

  describe "in queries" do
    it "works" do
      query_str = <<-GRAPHQL
      {
        piano: find(id: "Instrument/Piano") {
          id
          upcasedId
          ... on Instrument {
            family
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_piano = {
        "id" => "Instrument/Piano",
        "upcasedId" => "INSTRUMENT/PIANO",
        "family" => "KEYS",
      }
      assert_equal(expected_piano, res["data"]["piano"])
    end

    it "applies custom field attributes" do
      query_str = <<-GRAPHQL
      {
        find(id: "Ensemble/Bela Fleck and the Flecktones") {
          upcasedId
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_data = {
        "upcasedId" => "ENSEMBLE/BELA FLECK AND THE FLECKTONES",
        "name" => "Bela Fleck and the Flecktones"
      }
      assert_equal(expected_data, res["data"]["find"])
    end
  end

  describe ':DefinitionMethods' do
    module InterfaceA
      include GraphQL::Schema::Interface

      definition_methods do
        def some_method
          42
        end
      end
    end

    module InterfaceB
      include GraphQL::Schema::Interface
    end

    module InterfaceC
      include GraphQL::Schema::Interface
      definition_methods do
      end
    end

    module InterfaceD
      include InterfaceA

      definition_methods do
        def some_method
          'not 42'
        end
      end
    end

    module InterfaceE
      include InterfaceD
    end

    it "doesn't overwrite them when including multiple interfaces" do
      def_methods = InterfaceC::DefinitionMethods

      InterfaceC.module_eval do
        include InterfaceA
        include InterfaceB
      end

      assert_equal(InterfaceC::DefinitionMethods, def_methods)
    end

    it "follows the normal Ruby ancestor chain when including other interfaces" do
      assert_equal('not 42', InterfaceE.some_method)
    end
  end

  describe "comments" do
    class SchemaWithInterface < GraphQL::Schema
      module InterfaceWithComment
        include GraphQL::Schema::Interface
        comment "Interface comment"
      end

      class Query < GraphQL::Schema::Object
        implements InterfaceWithComment
      end

      query(Query)
    end

    it "assigns comment to the interface" do
      assert_equal("Interface comment", SchemaWithInterface::Query.interfaces[0].comment)
    end
  end

  describe "can implement other interfaces" do
    class InterfaceImplementsSchema < GraphQL::Schema
      module InterfaceA
        include GraphQL::Schema::Interface
        field :a, String

        def a; "a"; end
      end

      module InterfaceB
        include GraphQL::Schema::Interface
        implements InterfaceA
        field :b, String

        def b; "b"; end
      end

      class Query < GraphQL::Schema::Object
        implements InterfaceB
      end

      query(Query)
    end

    it "runs queries on inherited interfaces" do
      result = InterfaceImplementsSchema.execute("{ a b }")
      assert_equal "a", result["data"]["a"]
      assert_equal "b", result["data"]["b"]

      result2 = InterfaceImplementsSchema.execute(<<-GRAPHQL)
      {
        ... on InterfaceA {
          ... on InterfaceB {
            f1: a
            f2: b
          }
        }
      }
      GRAPHQL
      assert_equal "a", result2["data"]["f1"]
      assert_equal "b", result2["data"]["f2"]
    end

    it "shows up in introspection" do
      result = InterfaceImplementsSchema.execute("{ __type(name: \"InterfaceB\") { interfaces { name } } }")
      assert_equal ["InterfaceA"], result["data"]["__type"]["interfaces"].map { |i| i["name"] }
    end

    it "has the right structure" do
      expected_schema = <<-SCHEMA
interface InterfaceA {
  a: String
}

interface InterfaceB implements InterfaceA {
  a: String
  b: String
}

type Query implements InterfaceA & InterfaceB {
  a: String
  b: String
}
      SCHEMA
      assert_equal expected_schema, InterfaceImplementsSchema.to_definition
    end
  end

  describe "transitive implementation of same interface twice" do
    class TransitiveInterfaceSchema < GraphQL::Schema
      module Node
        include GraphQL::Schema::Interface
        field :id, ID

        def id; "id"; end
      end

      module Named
        include GraphQL::Schema::Interface
        implements Node
        field :name, String

        def name; "name"; end
      end

      module Timestamped
        include GraphQL::Schema::Interface
        implements Node
        field :timestamp, String

        def timestamp; "ts"; end
      end

      class BaseObject < GraphQL::Schema::Object
        implements Named
        implements Timestamped
      end

      class Thing < BaseObject
        implements Named
        implements Timestamped
      end

      class Query < GraphQL::Schema::Object
        field :thing, Thing
        def thing
          {}
        end
      end

      query(Query)
    end

    it "allows running queries on transitive interfaces" do
      result = TransitiveInterfaceSchema.execute("{ thing { id name timestamp } }")

      thing = result.dig("data", "thing")

      assert_equal "id", thing["id"]
      assert_equal "name", thing["name"]
      assert_equal "ts", thing["timestamp"]

      result2 = TransitiveInterfaceSchema.execute(<<-GRAPHQL)
      {
        thing {
          ...on Node { id }
          ...on Named {
            nid: id name
            ...on Node { nnid: id }
          }
          ... on Timestamped { tid: id timestamp }
        }
      }
      GRAPHQL

      thing2 = result2.dig("data", "thing")

      assert_equal "id", thing2["id"]
      assert_equal "id", thing2["nid"]
      assert_equal "id", thing2["tid"]
      assert_equal "name", thing2["name"]
      assert_equal "ts", thing2["timestamp"]
    end

    it "has the right structure" do
      expected_schema = <<-SCHEMA
interface Named implements Node {
  id: ID
  name: String
}

interface Node {
  id: ID
}

type Query {
  thing: Thing
}

type Thing implements Named & Node & Timestamped {
  id: ID
  name: String
  timestamp: String
}

interface Timestamped implements Node {
  id: ID
  timestamp: String
}
      SCHEMA
      assert_equal expected_schema, TransitiveInterfaceSchema.to_definition
    end

    it "only lists each implemented interface once when introspecting" do
      introspection = TransitiveInterfaceSchema.as_json
      thing_type = introspection.dig("data", "__schema", "types").find do |type|
        type["name"] == "Thing"
      end
      interfaces_names = thing_type["interfaces"].map { |i| i["name"] }.sort

      assert_equal ["Named", "Node", "Timestamped"], interfaces_names
    end
  end

  describe "supplying a fallback_value to a field" do
    DATABASE = [
      {id: "1", name: "Hash thing"},
      {id: "2"},
      {id: "3", name: nil},
      OpenStruct.new(id: "4", name: "OpenStruct thing"),
      OpenStruct.new(id: "5"),
      {id: "6", custom_name: "Hash Key Name"}
    ]

    class FallbackValueSchema < GraphQL::Schema
      module NodeWithFallbackInterface
        include GraphQL::Schema::Interface

        field :id, ID, null: false
        field :name, String, fallback_value: "fallback"
      end

      module NodeWithHashKeyFallbackInterface
        include GraphQL::Schema::Interface

        field :id, ID, null: false
        field :name, String, hash_key: :custom_name, fallback_value: "hash-key-fallback"
      end

      module NodeWithoutFallbackInterface
        include GraphQL::Schema::Interface

        field :id, ID, null: false
        field :name, String
      end

      module NodeWithNilFallbackInterface
        include GraphQL::Schema::Interface

        field :id, ID, null: false
        field :name, String, fallback_value: nil
      end

      class NodeWithFallbackType < GraphQL::Schema::Object
        implements NodeWithFallbackInterface
      end

      class NodeWithHashKeyFallbackType < GraphQL::Schema::Object
        implements NodeWithHashKeyFallbackInterface
      end

      class NodeWithNilFallbackType < GraphQL::Schema::Object
        implements NodeWithNilFallbackInterface
      end

      class NodeWithoutFallbackType < GraphQL::Schema::Object
        implements NodeWithoutFallbackInterface
      end

      class Query < GraphQL::Schema::Object
        field :fallback, [NodeWithFallbackType]
        def fallback
          DATABASE
        end

        field :hash_key_fallback, [NodeWithHashKeyFallbackType]
        def hash_key_fallback
          DATABASE
        end

        field :no_fallback, [NodeWithoutFallbackType]
        def no_fallback
          DATABASE
        end

        field :nil_fallback, [NodeWithNilFallbackType]
        def nil_fallback
          DATABASE
        end
      end

      query(Query)
    end

    it "uses fallback_value if supplied, but only if other ways don't work" do
      result = FallbackValueSchema.execute("{ fallback { id name } }")
      data = result["data"]["fallback"]
      expected = [
        {"id"=>"1", "name"=>"Hash thing"},
        {"id"=>"2", "name"=>"fallback"},
        {"id"=>"3", "name"=>nil},
        {"id"=>"4", "name"=>"OpenStruct thing"},
        {"id"=>"5", "name"=>"fallback"},
        {"id"=>"6", "name"=>"fallback"},
      ]

      assert_equal expected, data
    end

    it "uses fallback_value if supplied when hash key isn't present" do
      result = FallbackValueSchema.execute("{ hashKeyFallback { id name } }")
      data = result["data"]["hashKeyFallback"]
      expected = [
        {"id"=>"1", "name"=>"hash-key-fallback"},
        {"id"=>"2", "name"=>"hash-key-fallback"},
        {"id"=>"3", "name"=>"hash-key-fallback"},
        {"id"=>"4", "name"=>"hash-key-fallback"},
        {"id"=>"5", "name"=>"hash-key-fallback"},
        {"id"=>"6", "name"=>"Hash Key Name"},
      ]

      assert_equal expected, data
    end

    it "allows nil as fallback_value" do
      result = FallbackValueSchema.execute("{ nilFallback { id name } }")
      data = result["data"]["nilFallback"]
      expected = [
        {"id"=>"1", "name"=>"Hash thing"},
        {"id"=>"2", "name"=>nil},
        {"id"=>"3", "name"=>nil},
        {"id"=>"4", "name"=>"OpenStruct thing"},
        {"id"=>"5", "name"=>nil},
        {"id"=>"6", "name"=>nil},
      ]

      assert_equal expected, data
    end

    it "errors if no fallback_value is supplied and other ways don't work" do
      err = assert_raises RuntimeError do
        FallbackValueSchema.execute("{ noFallback { id name } }")
      end

      assert_includes err.message, "Failed to implement"
      # Doesn't error until it gets to the OpenStructs.
      assert_includes err.message, "OpenStruct"
    end
  end

  describe "migrated legacy tests" do
    let(:interface) { Dummy::Edible }

    it "has possible types" do
      expected_defns = [Dummy::Aspartame, Dummy::Cheese, Dummy::Honey, Dummy::Milk]
      assert_equal(expected_defns, Dummy::Schema.possible_types(interface).sort_by(&:graphql_name))
    end

    describe "query evaluation" do
      let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
      let(:query_string) {%|
        query fav {
          favoriteEdible { fatContent }
        }
      |}
      it "gets fields from the type for the given object" do
        expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04}}}
        assert_equal(expected, result)
      end
    end

    describe "mergeable query evaluation" do
      let(:result) { Dummy::Schema.execute(query_string, variables: {"cheeseId" => 2})}
      let(:query_string) {%|
        query fav {
          favoriteEdible { fatContent }
          favoriteEdible { origin }
        }
      |}
      it "gets fields from the type for the given object" do
        expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04, "origin"=>"Antiquity"}}}
        assert_equal(expected, result)
      end
    end

    describe "fragments" do
      let(:query_string) {%|
      {
        favoriteEdible {
          fatContent
          ... on LocalProduct {
            origin
          }
        }
      }
      |}
      let(:result) { Dummy::Schema.execute(query_string) }

      it "can apply interface fragments to an interface" do
        expected_result = { "data" => {
          "favoriteEdible" => {
            "fatContent" => 0.04,
            "origin" => "Antiquity",
          }
        } }

        assert_equal(expected_result, result)
      end

      describe "filtering members by type" do
        let(:query_string) {%|
        {
          allEdible {
            __typename
            ... on LocalProduct {
              origin
            }
          }
        }
        |}

        it "only applies fields to the right object" do
          expected_data = [
            {"__typename"=>"Cheese", "origin"=>"France"},
            {"__typename"=>"Cheese", "origin"=>"Netherlands"},
            {"__typename"=>"Cheese", "origin"=>"Spain"},
            {"__typename"=>"Milk", "origin"=>"Antiquity"},
          ]

          assert_equal expected_data, result["data"]["allEdible"]
        end
      end
    end


    describe "#resolve_type" do
      let(:result) { Dummy::Schema.execute(query_string) }
      let(:query_string) {%|
        {
          allEdible {
            __typename
            ... on Milk {
              milkFatContent: fatContent
            }
            ... on Cheese {
              cheeseFatContent: fatContent
            }
          }

          allEdibleAsMilk {
            __typename
            ... on Milk {
              fatContent
            }
          }
        }
      |}

      it 'returns correct types for general schema and specific interface' do
        expected_result = {
          # Uses schema-level resolve_type
          "allEdible"=>[
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.19},
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.3},
            {"__typename"=>"Cheese", "cheeseFatContent"=>0.065},
            {"__typename"=>"Milk", "milkFatContent"=>0.04}
          ],
          # Uses type-level resolve_type
          "allEdibleAsMilk"=>[
            {"__typename"=>"Milk", "fatContent"=>0.19},
            {"__typename"=>"Milk", "fatContent"=>0.3},
            {"__typename"=>"Milk", "fatContent"=>0.065},
            {"__typename"=>"Milk", "fatContent"=>0.04}
          ]
        }
        assert_equal expected_result, result["data"]
      end

      describe "in definition_methods when implementing another interface" do
        class InterfaceInheritanceSchema < GraphQL::Schema
          module Node
            include GraphQL::Schema::Interface
            definition_methods do
              def resolve_type(obj, ctx)
                raise "This should never be called -- it's overridden"
              end
            end
          end
          module Pet
            include GraphQL::Schema::Interface
            implements Node

            definition_methods do
              def resolve_type(obj, ctx)
                if obj[:name] == "Fifi"
                  Dog
                else
                  Cat
                end
              end
            end
          end
          class Cat < GraphQL::Schema::Object
            implements Pet
          end

          class Dog < GraphQL::Schema::Object
            implements Pet
          end

          class Query < GraphQL::Schema::Object
            field :pet, Pet do
              argument :name, String
            end

            def pet(name:)
              { name: name }
            end
          end

          query(Query)
          orphan_types(Cat, Dog)
        end

        it "calls the local definition, not the inherited one" do
          res = InterfaceInheritanceSchema.execute("{ pet(name: \"Fifi\") { __typename } }")
          assert_equal "Dog", res["data"]["pet"]["__typename"]

          res = InterfaceInheritanceSchema.execute("{ pet(name: \"Pepper\") { __typename } }")
          assert_equal "Cat", res["data"]["pet"]["__typename"]
        end
      end
    end
  end

  describe ".comment" do
    it "isn't inherited" do
      int1 = Module.new do
        include GraphQL::Schema::Interface
        graphql_name "Int1"
        comment "TODO: fix this"
      end

      int2 = Module.new do
        include int1
        graphql_name "Int2"
      end

      assert_equal "TODO: fix this", int1.comment
      assert_nil int2.comment
    end
  end
end
